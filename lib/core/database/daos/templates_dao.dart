import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/templates_table.dart';

part 'templates_dao.g.dart';

@DriftAccessor(tables: [TemplatesTable])
class TemplatesDao extends DatabaseAccessor<AppDatabase> with _$TemplatesDaoMixin {
  TemplatesDao(super.db);

  Stream<List<Template>> watchAll({String? channel}) {
    final q = select(templatesTable);
    if (channel != null && channel != 'all') {
      q.where((t) => t.channel.equals(channel) | t.channel.equals('all'));
    }
    q.orderBy([(t) => OrderingTerm(expression: t.name)]);
    return q.watch();
  }

  Future<List<Template>> getAll({String? channel}) {
    final q = select(templatesTable);
    if (channel != null && channel != 'all') {
      q.where((t) => t.channel.equals(channel) | t.channel.equals('all'));
    }
    return (q..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Future<Template?> getById(int id) =>
      (select(templatesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insert(TemplatesTableCompanion entry) =>
      into(templatesTable).insert(entry);

  Future<bool> update(TemplatesTableCompanion entry) =>
      updateRow(templatesTable, entry);

  Future<int> delete(int id) =>
      (deleteFrom(templatesTable)..where((t) => t.id.equals(id))).go();
}
