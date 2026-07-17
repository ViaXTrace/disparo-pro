import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/provider_repository.dart';

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProviderRepository(db);
});

final providersStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(providerRepositoryProvider);
  return repo.watchAll();
});

final defaultProviderProvider = FutureProvider((ref) {
  final repo = ref.watch(providerRepositoryProvider);
  return repo.getDefault();
});
