import 'package:drift/drift.dart';

class MessageLogsTable extends Table {
  @override
  String get tableName => 'message_logs';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get campaignId => integer()();
  IntColumn get contactId => integer()();
  TextColumn get phone => text()();
  TextColumn get channel => text()(); // sms | rcs | whatsapp
  TextColumn get status => text()();
  // pending | sent | delivered | read | failed | opted_out
  TextColumn get externalId => text().nullable()(); // Provider message ID
  TextColumn get errorMessage => text().nullable()();
  TextColumn get providerResponse => text().nullable()(); // JSON
  DateTimeColumn get sentAt => dateTime().nullable()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
