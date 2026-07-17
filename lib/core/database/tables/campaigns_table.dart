import 'package:drift/drift.dart';

import 'providers_table.dart';

@DataClassName('Campaign')
class CampaignsTable extends Table {
  @override
  String get tableName => 'campaigns';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 200)();
  TextColumn get channel => text()(); // sms | rcs | whatsapp
  TextColumn get status => text().withDefault(const Constant('draft'))();
  // draft | scheduled | running | paused | completed | failed
  TextColumn get messageBody => text()();
  TextColumn get mediaUrl => text().nullable()();
  IntColumn get contactGroupId => integer().nullable()();
  IntColumn get providerId => integer().references(ProvidersTable, #id)();
  IntColumn get templateId => integer().nullable()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get totalContacts => integer().withDefault(const Constant(0))();
  IntColumn get sent => integer().withDefault(const Constant(0))();
  IntColumn get delivered => integer().withDefault(const Constant(0))();
  IntColumn get failed => integer().withDefault(const Constant(0))();
  IntColumn get batchSize => integer().withDefault(const Constant(50))();
  IntColumn get delayBetweenBatchesMs =>
      integer().withDefault(const Constant(500))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
