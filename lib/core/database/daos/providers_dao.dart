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
    if (entry.isDefault.value) await _clearDefault();
    return into(providersTable).insert(entry);
  }

  Future<bool> update(ProvidersTableCompanion entry) async {
    if (entry.isDefault.value) await _clearDefault();
    return updateRow(providersTable, entry);
  }

  Future<void> setDefault(int id) async {
    await _clearDefault();
    await (update(providersTable)..where((t) => t.id.equals(id)))
        .write(const ProvidersTableCompanion(isDefault: Value(true)));
  }

  Future<int> delete(int id) =>
      (deleteFrom(providersTable)..where((t) => t.id.equals(id))).go();

  Future<void> _clearDefault() =>
      (update(providersTable)..where((t) => t.isDefault.equals(true)))
          .write(const ProvidersTableCompanion(isDefault: Value(false)));
}
