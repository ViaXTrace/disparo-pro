import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/campaign_repository.dart';

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CampaignRepository(db);
});

final campaignsStreamProvider = StreamProvider.family<List<Campaign>, String?>((ref, filter) {
  final repo = ref.watch(campaignRepositoryProvider);
  return repo.watchAll(statusFilter: filter);
});

final campaignDetailProvider = StreamProvider.family<Campaign?, int>((ref, id) {
  final repo = ref.watch(campaignRepositoryProvider);
  return repo.watchById(id);
});

final campaignStatsProvider = FutureProvider.family<Map<String, int>, int>((ref, id) {
  final repo = ref.watch(campaignRepositoryProvider);
  return repo.getStats(id);
});

final campaignLogsProvider = StreamProvider.family<List<MessageLog>, int>((ref, id) {
  final repo = ref.watch(campaignRepositoryProvider);
  return repo.watchLogs(id);
});

final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final repo = ref.watch(campaignRepositoryProvider);
  return repo.getDashboardStats();
});
