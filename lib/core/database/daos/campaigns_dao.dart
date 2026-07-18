import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/campaigns_table.dart';
import '../tables/message_logs_table.dart';

part 'campaigns_dao.g.dart';

@DriftAccessor(tables: [CampaignsTable, MessageLogsTable])
class CampaignsDao extends DatabaseAccessor<AppDatabase> with _$CampaignsDaoMixin {
  CampaignsDao(super.db);

  Stream<List<Campaign>> watchAll({String? statusFilter}) {
    final q = select(campaignsTable);
    if (statusFilter != null && statusFilter != 'all') {
      q.where((t) => t.status.equals(statusFilter));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch();
  }

  Future<List<Campaign>> getAll() =>
      (select(campaignsTable)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<Campaign?> getById(int id) =>
      (select(campaignsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Campaign?> watchById(int id) =>
      (select(campaignsTable)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> insert(CampaignsTableCompanion entry) =>
      into(campaignsTable).insert(entry);

  Future<bool> updateCampaign(CampaignsTableCompanion entry) async {
    final count = await (update(campaignsTable)
          ..where((t) => t.id.equals(entry.id.value)))
        .write(entry);
    return count > 0;
  }

  Future<void> updateStatus(int id, String status) =>
      (update(campaignsTable)..where((t) => t.id.equals(id)))
          .write(CampaignsTableCompanion(status: Value(status)));

  Future<void> updateProgress(int id, {required int sent, required int failed}) =>
      (update(campaignsTable)..where((t) => t.id.equals(id))).write(
        CampaignsTableCompanion(sent: Value(sent), failed: Value(failed)),
      );

  Future<int> deleteCampaign(int id) async {
    await (delete(messageLogsTable)..where((t) => t.campaignId.equals(id))).go();
    return (delete(campaignsTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<MessageLog>> watchLogs(int campaignId) =>
      (select(messageLogsTable)
            ..where((t) => t.campaignId.equals(campaignId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<MessageLog>> getLogs(int campaignId) =>
      (select(messageLogsTable)..where((t) => t.campaignId.equals(campaignId))).get();

  Future<List<MessageLog>> getAllLogs() =>
      (select(messageLogsTable)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<int> insertLog(MessageLogsTableCompanion entry) =>
      into(messageLogsTable).insert(entry);

  Future<void> updateLogStatus(int logId, String status, {String? externalId}) async {
    final companion = MessageLogsTableCompanion(
      status: Value(status),
      externalId: externalId != null ? Value(externalId) : const Value.absent(),
      deliveredAt: status == 'delivered' ? Value(DateTime.now()) : const Value.absent(),
      readAt: status == 'read' ? Value(DateTime.now()) : const Value.absent(),
    );
    await (update(messageLogsTable)..where((t) => t.id.equals(logId))).write(companion);
  }

  Future<Map<String, int>> getCampaignStats(int campaignId) async {
    final logs = await getLogs(campaignId);
    return {
      'total': logs.length,
      'sent': logs.where((l) => l.status == 'sent' || l.status == 'delivered' || l.status == 'read').length,
      'delivered': logs.where((l) => l.status == 'delivered' || l.status == 'read').length,
      'read': logs.where((l) => l.status == 'read').length,
      'failed': logs.where((l) => l.status == 'failed').length,
    };
  }

  Future<Map<String, int>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfDay   = DateTime(now.year, now.month, now.day);
    final startOfWeek  = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    final allLogs = await select(messageLogsTable).get();

    bool isAfter(MessageLog l, DateTime threshold) =>
        l.createdAt != null && l.createdAt.isAfter(threshold);

    final today = allLogs.where((l) => isAfter(l, startOfDay)).toList();
    final week  = allLogs.where((l) => isAfter(l, startOfWeek)).toList();
    final month = allLogs.where((l) => isAfter(l, startOfMonth)).toList();

    return {
      'sent_today':      today.where((l) => l.status != 'pending').length,
      'delivered_today': today.where((l) => l.status == 'delivered' || l.status == 'read').length,
      'failed_today':    today.where((l) => l.status == 'failed').length,
      'sent_week':       week.where((l)  => l.status != 'pending').length,
      'delivered_week':  week.where((l)  => l.status == 'delivered' || l.status == 'read').length,
      'failed_week':     week.where((l)  => l.status == 'failed').length,
      'sent_month':      month.where((l) => l.status != 'pending').length,
      'delivered_month': month.where((l) => l.status == 'delivered' || l.status == 'read').length,
      'failed_month':    month.where((l) => l.status == 'failed').length,
      // Aggregate campaign counts
      'total_campaigns': (await select(campaignsTable).get()).length,
      'running_campaigns': (await (select(campaignsTable)
            ..where((t) => t.status.equals('running'))).get()).length,
    };
  }

  /// Per-channel breakdown of sent/delivered across ALL time (for reports).
  Future<Map<String, Map<String, int>>> getChannelStats() async {
    final logs = await select(messageLogsTable).get();
    final channels = <String, Map<String, int>>{};
    for (final log in logs) {
      final ch = channels.putIfAbsent(log.channel, () => {'sent': 0, 'delivered': 0, 'failed': 0});
      if (log.status != 'pending') ch['sent'] = (ch['sent'] ?? 0) + 1;
      if (log.status == 'delivered' || log.status == 'read') ch['delivered'] = (ch['delivered'] ?? 0) + 1;
      if (log.status == 'failed') ch['failed'] = (ch['failed'] ?? 0) + 1;
    }
    return channels;
  }
}
