import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import '../gateway/gateway_registry.dart';
import '../gateway/message_gateway.dart';

class DispatchTasks {
  static const sendCampaign = 'send_campaign';
}

/// Entry point called by WorkManager in a background isolate.
/// Must be a top-level function annotated with @pragma.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != DispatchTasks.sendCampaign) return true;

    final campaignId = inputData?['campaign_id'] as int?;
    if (campaignId == null) return false;

    // Open DB in background isolate (cannot reuse foreground instance)
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'disparo_pro.db'));
    final db = AppDatabase.forBackground(NativeDatabase(file));

    try {
      final campaign = await db.campaignsDao.getById(campaignId);
      if (campaign == null) return false;

      final provider = await db.providersDao.getById(campaign.providerId);
      if (provider == null) return false;

      final credentials = jsonDecode(provider.credentials) as Map<String, dynamic>;
      final gateway = GatewayRegistry.build(provider.type);
      await gateway.initialize(credentials);

      final channel = MessageChannel.values.firstWhere(
        (c) => c.name == campaign.channel,
        orElse: () => MessageChannel.sms,
      );

      // Fetch contacts from the assigned group
      List<String> phones = [];
      if (campaign.contactGroupId != null) {
        final contacts = await db.contactsDao.getGroupContacts(campaign.contactGroupId!);
        phones = contacts.where((c) => !c.optedOut).map((c) => c.phone).toList();
      }

      if (phones.isEmpty) {
        await db.campaignsDao.updateStatus(campaignId, 'completed');
        return true;
      }

      // Persist total and mark as running
      await (db.update(db.campaignsTable)..where((t) => t.id.equals(campaignId))).write(
        CampaignsTableCompanion(
          totalContacts: Value(phones.length),
          startedAt: Value(DateTime.now()),
          status: const Value('running'),
        ),
      );

      int sent = 0;
      int failed = 0;
      final batchSize = campaign.batchSize;
      final delayMs = campaign.delayBetweenBatchesMs;

      for (var i = 0; i < phones.length; i += batchSize) {
        // Check for external pause signal
        final current = await db.campaignsDao.getById(campaignId);
        if (current?.status == 'paused') break;

        final batch = phones.sublist(i, (i + batchSize).clamp(0, phones.length));

        for (final phone in batch) {
          final result = await gateway.sendMessage(
            to: phone,
            body: campaign.messageBody,
            channel: channel,
            mediaUrl: campaign.mediaUrl,
          );

          final logStatus = result.success ? 'sent' : 'failed';
          final rawJson = result.rawResponse != null ? jsonEncode(result.rawResponse) : null;

          await db.campaignsDao.insertLog(MessageLogsTableCompanion.insert(
            campaignId: campaignId,
            contactId: 0,
            phone: phone,
            channel: campaign.channel,
            status: Value(logStatus),
            externalId: Value(result.externalId),
            errorMessage: Value(result.errorMessage),
            providerResponse: Value(rawJson),
            sentAt: result.success ? Value(DateTime.now()) : const Value.absent(),
          ));

          if (result.success) {
            sent++;
          } else {
            failed++;
          }
        }

        await db.campaignsDao.updateProgress(campaignId, sent: sent, failed: failed);
        await _notifyProgress(campaignId, campaign.name, sent, phones.length);

        if (i + batchSize < phones.length) {
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }

      // Final status
      final finalStatus = sent > 0 ? 'completed' : 'failed';
      await (db.update(db.campaignsTable)..where((t) => t.id.equals(campaignId))).write(
        CampaignsTableCompanion(
          status: Value(finalStatus),
          completedAt: Value(DateTime.now()),
        ),
      );
      await _notifyDone(campaignId, campaign.name, sent, failed);
      return true;
    } catch (e) {
      await db.campaignsDao.updateStatus(campaignId, 'failed');
      return false;
    } finally {
      await db.close();
    }
  });
}

// ── Notification helpers ────────────────────────────────────────────────────

final _notifications = FlutterLocalNotificationsPlugin();

Future<void> _notifyProgress(int id, String name, int sent, int total) async {
  await _notifications.show(
    id,
    'Enviando: $name',
    '$sent / $total mensagens enviadas',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'campaign_progress',
        'Campanhas em andamento',
        channelDescription: 'Progresso de campanhas de disparo',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        showProgress: true,
        maxProgress: total,
        progress: sent,
      ),
    ),
  );
}

Future<void> _notifyDone(int id, String name, int sent, int failed) async {
  await _notifications.cancel(id);
  await _notifications.show(
    id + 10000,
    'Campanha concluída: $name',
    '$sent enviadas · $failed falhas',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'campaign_done',
        'Campanhas concluídas',
        channelDescription: 'Notificações de campanhas finalizadas',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}
