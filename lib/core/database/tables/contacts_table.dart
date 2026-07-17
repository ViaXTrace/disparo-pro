import 'package:drift/drift.dart';

class ContactsTable extends Table {
  @override
  String get tableName => 'contacts';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 200)();
  TextColumn get phone => text().withLength(max: 20)();
  TextColumn get email => text().nullable().withLength(max: 200)();
  TextColumn get extraData => text().nullable()(); // JSON blob for custom fields
  BoolColumn get optedOut => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {phone}
      ];
}
