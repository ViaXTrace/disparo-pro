import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/providers_table.dart';

part 'providers_dao.g.dart';

@DriftAccessor(tables: [ProvidersTable])
class ProvidersDao extends DatabaseAccessor<AppDatabase> with _$ProvidersDaoMixin {
  ProvidersDao(super.db);

  Stream<List<ProviderConfig>> watchAll() =>
      (select(providersTable)..orderBy([(t) => OrderingTerm.desc(t.isDefault)])).watch();

  Future<List<ProviderConfig>> getAll() =>
      (select(providersTable)..orderBy([(t) => OrderingTerm.desc(t.isDefault)])).get();

  Future<ProviderConfig?> getById(int id) =>
      (select(providersTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ProviderConfig?> getDefault() =>
      (select(providersTable)..where((t) => t.isDefault.equals(true))).getSingleOrNull();

  Future<int> insert(ProvidersTableCompanion entry) async {
    if (entry.isDefault == const Value(true)) await _clearDefault();
    return into(providersTable).insert(entry);
  }

  Future<bool> updateProvider(ProvidersTableCompanion entry) async {
    if (entry.isDefault.present && entry.isDefault.value) await _clearDefault();
    final count = await (update(providersTable)
          ..where((t) => t.id.equals(entry.id.value)))
        .write(entry);
    return count > 0;
  }

  Future<void> setDefault(int id) async {
    await _clearDefault();
    await (update(providersTable)..where((t) => t.id.equals(id)))
        .write(const ProvidersTableCompanion(isDefault: Value(true)));
  }

  Future<int> deleteProvider(int id) =>
      (delete(providersTable)..where((t) => t.id.equals(id))).go();

  Future<void> _clearDefault() =>
      (update(providersTable)..where((t) => t.isDefault.equals(true)))
          .write(const ProvidersTableCompanion(isDefault: Value(false)));
}
