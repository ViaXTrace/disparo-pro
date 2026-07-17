import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/campaigns_table.dart';
import '../tables/message_logs_table.dart';

part 'campaigns_dao.g.dart';

@DriftAccessor(tables: [CampaignsTable, MessageLogsTable])
class CampaignsDao extends DatabaseAccessor<AppDatabase> with _$CampaignsDaoMixin {
  CampaignsDao(super.db);

  // ── Campaigns ────────────────────────────────────────────────────────────

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
    await (deleteFrom(messageLogsTable)..where((t) => t.campaignId.equals(id))).go();
    return (deleteFrom(campaignsTable)..where((t) => t.id.equals(id))).go();
  }

  // ── Message Logs ─────────────────────────────────────────────────────────

  Stream<List<MessageLog>> watchLogs(int campaignId) =>
      (select(messageLogsTable)
            ..where((t) => t.campaignId.equals(campaignId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<MessageLog>> getLogs(int campaignId) =>
      (select(messageLogsTable)..where((t) => t.campaignId.equals(campaignId))).get();

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

  // ── Dashboard stats ───────────────────────────────────────────────────────

  Future<Map<String, int>> getDashboardStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final logsToday = await (select(messageLogsTable)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(startOfDay)))
        .get();
    return {
      'sent_today': logsToday.where((l) => l.status != 'pending').length,
      'delivered_today': logsToday.where((l) => l.status == 'delivered' || l.status == 'read').length,
      'failed_today': logsToday.where((l) => l.status == 'failed').length,
    };
  }
}
