import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'tables/campaigns_table.dart';
import 'tables/contact_groups_table.dart';
import 'tables/contacts_table.dart';
import 'tables/message_logs_table.dart';
import 'tables/providers_table.dart';
import 'tables/templates_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  ContactsTable,
  ContactGroupsTable,
  ContactGroupMembersTable,
  CampaignsTable,
  MessageLogsTable,
  ProvidersTable,
  TemplatesTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
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
