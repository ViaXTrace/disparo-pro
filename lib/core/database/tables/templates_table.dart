import 'package:drift/drift.dart';

@DataClassName('Template')
class TemplatesTable extends Table {
  @override
  String get tableName => 'templates';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 200)();
  TextColumn get channel => text().withDefault(const Constant('all'))();
  TextColumn get body => text()();
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get variables => text().nullable()(); // JSON list
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
