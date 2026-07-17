import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
import 'dart:io';

import '../database/app_database.dart';
import '../gateway/gateway_registry.dart';
import '../notifications/notification_service.dart';

/// Nomes das tasks do WorkManager
class DispatchTasks {
  static const sendCampaign = 'sendCampaignTask';
  static const checkDelivery = 'checkDeliveryTask';
}

/// Worker que executa em background (WorkManager).
/// Processa fila de disparos quando o app está em segundo plano.
class DispatchWorker {
  static Future<bool> run(String task, Map<String, dynamic>? data) async {
    try {
      final db = await _openDb();
      switch (task) {
        case DispatchTasks.sendCampaign:
          await _processCampaign(db, data);
        case DispatchTasks.checkDelivery:
          await _checkDeliveries(db);
        default:
          return false;
      }
      await db.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _processCampaign(
      AppDatabase db, Map<String, dynamic>? data) async {
    if (data == null) return;
    final campaignId = data['campaign_id'] as int?;
    if (campaignId == null) return;

    // Mark as running
    await (db.update(db.campaignsTable)
          ..where((t) => t.id.equals(campaignId)))
        .write(CampaignsTableCompanion(
      status: const Value('running'),
      startedAt: Value(DateTime.now()),
    ));

    // Load campaign + provider
    final campaign = await (db.select(db.campaignsTable)
          ..where((t) => t.id.equals(campaignId)))
        .getSingle();

    final provider = await (db.select(db.providersTable)
          ..where((t) => t.id.equals(campaign.providerId)))
        .getSingle();

    final credentials = jsonDecode(provider.credentials) as Map<String, dynamic>;
    final gateway = GatewayRegistry.build(provider.type);
    await gateway.initialize(credentials);

    final channel = MessageChannel.values.firstWhere(
      (c) => c.name == campaign.channel,
      orElse: () => MessageChannel.sms,
    );

    // Load contacts from group
    List<int> contactIds = [];
    if (campaign.contactGroupId != null) {
      final members = await (db.select(db.contactGroupMembersTable)
            ..where((t) => t.groupId.equals(campaign.contactGroupId!)))
          .get();
      contactIds = members.map((m) => m.contactId).toList();
    }

    int sent = 0, failed = 0;
    for (final contactId in contactIds) {
      final contact = await (db.select(db.contactsTable)
            ..where((t) => t.id.equals(contactId)))
          .getSingleOrNull();
      if (contact == null || contact.optedOut) continue;

      final result = await gateway.sendMessage(
        to: contact.phone,
        body: campaign.messageBody,
        channel: channel,
      );

      await db.into(db.messageLogsTable).insert(MessageLogsTableCompanion(
            campaignId: Value(campaignId),
            contactId: Value(contactId),
            phone: Value(contact.phone),
            channel: Value(campaign.channel),
            status: Value(result.success ? 'sent' : 'failed'),
            externalId: Value(result.externalId),
            errorMessage: Value(result.errorMessage),
            sentAt: result.success ? Value(DateTime.now()) : const Value(null),
          ));

      if (result.success) sent++; else failed++;

      await (db.update(db.campaignsTable)
            ..where((t) => t.id.equals(campaignId)))
          .write(CampaignsTableCompanion(
        sent: Value(sent),
        failed: Value(failed),
      ));

      await Future.delayed(Duration(milliseconds: campaign.delayBetweenBatchesMs));
    }

    await (db.update(db.campaignsTable)
          ..where((t) => t.id.equals(campaignId)))
        .write(CampaignsTableCompanion(
      status: const Value('completed'),
      completedAt: Value(DateTime.now()),
    ));

    await NotificationService.instance.showCampaignCompleted(
      campaignName: campaign.name,
      sent: sent,
      failed: failed,
    );
  }

  static Future<void> _checkDeliveries(AppDatabase db) async {
    // TODO: query pending logs and update statuses via provider
  }

  static Future<AppDatabase> _openDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'disparo_pro.db'));
    return AppDatabase.forBackground(NativeDatabase(file));
  }
}
