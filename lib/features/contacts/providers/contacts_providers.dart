import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/contact_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ContactRepository(db);
});

final contactSearchProvider = StateProvider<String>((ref) => '');

final contactsStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  final search = ref.watch(contactSearchProvider);
  return repo.watchAll(search: search.isEmpty ? null : search);
});

final contactCountProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return repo.count();
});

final contactGroupsStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return repo.watchGroups();
});

final groupContactCountProvider = FutureProvider.family<int, int>((ref, groupId) {
  final repo = ref.watch(contactRepositoryProvider);
  return repo.countGroupContacts(groupId);
});
