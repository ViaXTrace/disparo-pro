import 'package:drift/drift.dart';

@DataClassName('ContactGroup')
class ContactGroupsTable extends Table {
  @override
  String get tableName => 'contact_groups';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ContactGroupMember')
class ContactGroupMembersTable extends Table {
  @override
  String get tableName => 'contact_group_members';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer()();
  IntColumn get contactId => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [{groupId, contactId}];
}
