import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/campaigns_dao.dart';
import 'daos/contacts_dao.dart';
import 'daos/providers_dao.dart';
import 'daos/templates_dao.dart';
import 'tables/campaigns_table.dart';
import 'tables/contact_groups_table.dart';
import 'tables/contacts_table.dart';
import 'tables/message_logs_table.dart';
import 'tables/providers_table.dart';
import 'tables/templates_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ContactsTable,
    ContactGroupsTable,
    ContactGroupMembersTable,
    CampaignsTable,
    MessageLogsTable,
    ProvidersTable,
    TemplatesTable,
  ],
  daos: [
    ContactsDao,
    CampaignsDao,
    ProvidersDao,
    TemplatesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For WorkManager background isolate — pass executor directly.
  AppDatabase.forBackground(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {},
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'disparo_pro.db'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase must be overridden in ProviderScope');
});
