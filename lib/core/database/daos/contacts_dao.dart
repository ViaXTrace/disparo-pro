import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/contact_groups_table.dart';
import '../tables/contacts_table.dart';

part 'contacts_dao.g.dart';

@DriftAccessor(tables: [ContactsTable, ContactGroupsTable, ContactGroupMembersTable])
class ContactsDao extends DatabaseAccessor<AppDatabase> with _$ContactsDaoMixin {
  ContactsDao(super.db);

  Stream<List<Contact>> watchAll({String? search}) {
    final q = select(contactsTable);
    if (search != null && search.isNotEmpty) {
      q.where((t) =>
          t.name.like('%$search%') | t.phone.like('%$search%'));
    }
    q.orderBy([(t) => OrderingTerm(expression: t.name)]);
    return q.watch();
  }

  Future<List<Contact>> getAll() =>
      (select(contactsTable)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();

  Future<Contact?> getById(int id) =>
      (select(contactsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Contact?> getByPhone(String phone) =>
      (select(contactsTable)..where((t) => t.phone.equals(phone))).getSingleOrNull();

  Future<int> insert(ContactsTableCompanion entry) =>
      into(contactsTable).insert(entry, mode: InsertMode.insertOrIgnore);

  Future<void> bulkInsert(List<ContactsTableCompanion> entries) =>
      batch((b) => b.insertAll(contactsTable, entries, mode: InsertMode.insertOrIgnore));

  Future<bool> updateContact(ContactsTableCompanion entry) async {
    final count = await (update(contactsTable)
          ..where((t) => t.id.equals(entry.id.value)))
        .write(entry);
    return count > 0;
  }

  Future<int> deleteContact(int id) =>
      (delete(contactsTable)..where((t) => t.id.equals(id))).go();

  Future<void> setOptOut(int id, bool value) =>
      (update(contactsTable)..where((t) => t.id.equals(id)))
          .write(ContactsTableCompanion(optedOut: Value(value)));

  Future<int> count() async {
    final count = contactsTable.id.count();
    final q = selectOnly(contactsTable)..addColumns([count]);
    final row = await q.getSingle();
    return row.read(count) ?? 0;
  }

  Stream<List<ContactGroup>> watchGroups() =>
      (select(contactGroupsTable)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();

  Future<List<ContactGroup>> getGroups() =>
      (select(contactGroupsTable)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();

  Future<ContactGroup?> getGroupById(int id) =>
      (select(contactGroupsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertGroup(ContactGroupsTableCompanion entry) =>
      into(contactGroupsTable).insert(entry);

  Future<int> deleteGroup(int id) async {
    await (delete(contactGroupMembersTable)
          ..where((t) => t.groupId.equals(id)))
        .go();
    return (delete(contactGroupsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Contact>> getGroupContacts(int groupId) async {
    final members = await (select(contactGroupMembersTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();
    if (members.isEmpty) return [];
    final ids = members.map((m) => m.contactId).toList();
    return (select(contactsTable)
          ..where((t) => t.id.isIn(ids)))
        .get();
  }

  Future<int> countGroupContacts(int groupId) async {
    final count = contactGroupMembersTable.id.count();
    final q = selectOnly(contactGroupMembersTable)
      ..addColumns([count])
      ..where(contactGroupMembersTable.groupId.equals(groupId));
    final row = await q.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> addContactsToGroup(int groupId, List<int> contactIds) => batch((b) {
        b.insertAll(
          contactGroupMembersTable,
          contactIds
              .map((cid) => ContactGroupMembersTableCompanion(
                    groupId: Value(groupId),
                    contactId: Value(cid),
                  ))
              .toList(),
          mode: InsertMode.insertOrIgnore,
        );
      });

  Future<int> removeContactFromGroup(int groupId, int contactId) =>
      (delete(contactGroupMembersTable)
            ..where((t) => t.groupId.equals(groupId) & t.contactId.equals(contactId)))
          .go();
}
