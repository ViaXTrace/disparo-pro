import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/templates_dao.dart';
import '../data/template_repository.dart';

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TemplateRepository(db);
});

final templatesStreamProvider = StreamProvider.family<List<Template>, String?>((ref, channel) {
  final repo = ref.watch(templateRepositoryProvider);
  return repo.watchAll(channel: channel);
});
