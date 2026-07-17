import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/contacts_dao.dart';
import '../../../core/database/tables/contact_groups_table.dart';
import '../../../core/database/tables/contacts_table.dart';

class ContactRepository {
  final ContactsDao _dao;

  ContactRepository(AppDatabase db) : _dao = db.contactsDao;

  // ── Contacts ──────────────────────────────────────────────────────────────

  Stream<List<Contact>> watchAll({String? search}) => _dao.watchAll(search: search);
  Future<List<Contact>> getAll() => _dao.getAll();
  Future<Contact?> getById(int id) => _dao.getById(id);
  Future<int> count() => _dao.count();

  Future<Contact> add({
    required String name,
    required String phone,
    String? email,
    Map<String, dynamic>? extra,
  }) async {
    final id = await _dao.insert(ContactsTableCompanion.insert(
      name: name,
      phone: _normalizePhone(phone),
      email: Value(email),
      extraData: Value(extra != null ? jsonEncode(extra) : null),
    ));
    return (await _dao.getById(id))!;
  }

  Future<void> update(Contact contact, {
    String? name,
    String? phone,
    String? email,
    bool? optedOut,
  }) => _dao.update(ContactsTableCompanion(
        id: Value(contact.id),
        name: name != null ? Value(name) : const Value.absent(),
        phone: phone != null ? Value(_normalizePhone(phone)) : const Value.absent(),
        email: email != null ? Value(email) : const Value.absent(),
        optedOut: optedOut != null ? Value(optedOut) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));

  Future<int> delete(int id) => _dao.delete(id);
  Future<void> setOptOut(int id, bool value) => _dao.setOptOut(id, value);

  /// Imports from CSV string. Returns (imported, duplicates).
  Future<({int imported, int duplicates})> importFromCsv(
    String csvContent, {
    required int phoneColumnIndex,
    required int nameColumnIndex,
    bool hasHeader = true,
  }) async {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    final data = hasHeader && rows.isNotEmpty ? rows.sublist(1) : rows;

    int imported = 0;
    int duplicates = 0;

    final companions = <ContactsTableCompanion>[];
    for (final row in data) {
      if (row.isEmpty) continue;
      final phone = _normalizePhone(row[phoneColumnIndex]?.toString().trim() ?? '');
      if (phone.isEmpty) continue;
      final name = nameColumnIndex < row.length
          ? row[nameColumnIndex]?.toString().trim() ?? phone
          : phone;

      companions.add(ContactsTableCompanion.insert(
        name: name,
        phone: phone,
      ));
    }

    // Insert in batches of 500
    for (var i = 0; i < companions.length; i += 500) {
      final batch = companions.sublist(i, i + 500 > companions.length ? companions.length : i + 500);
      await _dao.bulkInsert(batch);
      imported += batch.length;
    }

    duplicates = data.length - imported;
    return (imported: imported, duplicates: duplicates < 0 ? 0 : duplicates);
  }

  // ── Groups ────────────────────────────────────────────────────────────────

  Stream<List<ContactGroup>> watchGroups() => _dao.watchGroups();
  Future<List<ContactGroup>> getGroups() => _dao.getGroups();
  Future<ContactGroup?> getGroupById(int id) => _dao.getGroupById(id);
  Future<int> countGroupContacts(int groupId) => _dao.countGroupContacts(groupId);
  Future<List<Contact>> getGroupContacts(int groupId) => _dao.getGroupContacts(groupId);

  Future<ContactGroup> createGroup({required String name, String? description}) async {
    final id = await _dao.insertGroup(ContactGroupsTableCompanion.insert(
      name: name,
      description: Value(description),
    ));
    return (await _dao.getGroupById(id))!;
  }

  Future<int> deleteGroup(int id) => _dao.deleteGroup(id);

  Future<void> addContactsToGroup(int groupId, List<int> contactIds) =>
      _dao.addContactsToGroup(groupId, contactIds);

  String _normalizePhone(String phone) {
    // Keep only digits and + at start
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return phone.trim();
    // Ensure Brazilian number has country code
    if (!digits.startsWith('+') && !digits.startsWith('55') && digits.length <= 11) {
      return '55$digits';
    }
    return digits;
  }
}
