import 'package:drift/drift.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/campaigns_dao.dart';
import '../../../core/background/dispatch_worker.dart';

class CampaignRepository {
  final CampaignsDao _dao;

  CampaignRepository(AppDatabase db) : _dao = db.campaignsDao;

  Stream<List<Campaign>> watchAll({String? statusFilter}) =>
      _dao.watchAll(statusFilter: statusFilter);

  Stream<Campaign?> watchById(int id) => _dao.watchById(id);

  Future<List<Campaign>> getAll() => _dao.getAll();

  Future<Campaign?> getById(int id) => _dao.getById(id);

  Future<Campaign> create({
    required String name,
    required String channel,
    required String messageBody,
    required int providerId,
    int? contactGroupId,
    int? templateId,
    String? mediaUrl,
    DateTime? scheduledAt,
    int batchSize = 50,
    int delayBetweenBatchesMs = 500,
  }) async {
    final id = await _dao.insert(CampaignsTableCompanion.insert(
      name: name,
      channel: channel,
      messageBody: messageBody,
      providerId: providerId,
      contactGroupId: Value(contactGroupId),
      templateId: Value(templateId),
      mediaUrl: Value(mediaUrl),
      scheduledAt: Value(scheduledAt),
      batchSize: Value(batchSize),
      delayBetweenBatchesMs: Value(delayBetweenBatchesMs),
    ));
    return (await _dao.getById(id))!;
  }

  Future<void> update(Campaign campaign, {
    String? name,
    String? channel,
    String? messageBody,
    int? providerId,
    int? contactGroupId,
    int? templateId,
    DateTime? scheduledAt,
    int? batchSize,
    int? delayBetweenBatchesMs,
  }) => _dao.updateCampaign(CampaignsTableCompanion(
        id: Value(campaign.id),
        name: name != null ? Value(name) : const Value.absent(),
        channel: channel != null ? Value(channel) : const Value.absent(),
        messageBody: messageBody != null ? Value(messageBody) : const Value.absent(),
        providerId: providerId != null ? Value(providerId) : const Value.absent(),
        contactGroupId: contactGroupId != null ? Value(contactGroupId) : const Value.absent(),
        templateId: templateId != null ? Value(templateId) : const Value.absent(),
        scheduledAt: scheduledAt != null ? Value(scheduledAt) : const Value.absent(),
        batchSize: batchSize != null ? Value(batchSize) : const Value.absent(),
        delayBetweenBatchesMs: delayBetweenBatchesMs != null ? Value(delayBetweenBatchesMs) : const Value.absent(),
      ));

  Future<int> delete(int id) => _dao.deleteCampaign(id);

  Future<Map<String, int>> getStats(int campaignId) => _dao.getCampaignStats(campaignId);

  Future<Map<String, int>> getDashboardStats() => _dao.getDashboardStats();

  Stream<List<MessageLog>> watchLogs(int campaignId) => _dao.watchLogs(campaignId);

  /// Starts the campaign immediately via WorkManager background task.
  Future<void> dispatch(int campaignId) async {
    await _dao.updateStatus(campaignId, 'running');
    await Workmanager().registerOneOffTask(
      'campaign_$campaignId',
      DispatchTasks.sendCampaign,
      inputData: {'campaign_id': campaignId},
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  Future<void> pause(int id) => _dao.updateStatus(id, 'paused');
  Future<void> resume(int id) => dispatch(id);

  /// Schedules the campaign to run at the given time.
  Future<void> schedule(int campaignId, DateTime at) async {
    final delay = at.difference(DateTime.now());
    if (delay.isNegative) {
      await dispatch(campaignId);
      return;
    }
    await _dao.updateStatus(campaignId, 'scheduled');
    await Workmanager().registerOneOffTask(
      'campaign_scheduled_$campaignId',
      DispatchTasks.sendCampaign,
      inputData: {'campaign_id': campaignId},
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
