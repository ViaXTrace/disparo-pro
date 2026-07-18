import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/contacts_dao.dart';
import 'vcf_parser.dart';

class ContactRepository {
  final ContactsDao _dao;

  ContactRepository(AppDatabase db) : _dao = db.contactsDao;

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
  }) => _dao.updateContact(ContactsTableCompanion(
        id: Value(contact.id),
        name: name != null ? Value(name) : const Value.absent(),
        phone: phone != null ? Value(_normalizePhone(phone)) : const Value.absent(),
        email: email != null ? Value(email) : const Value.absent(),
        optedOut: optedOut != null ? Value(optedOut) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));

  Future<int> delete(int id) => _dao.deleteContact(id);
  Future<void> setOptOut(int id, bool value) => _dao.setOptOut(id, value);

  // ── CSV Import ─────────────────────────────────────────────────────────────

  Future<({int imported, int duplicates})> importFromCsv(
    String csvContent, {
    required int phoneColumnIndex,
    required int nameColumnIndex,
    bool hasHeader = true,
  }) async {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    final data = hasHeader && rows.isNotEmpty ? rows.sublist(1) : rows;

    int imported = 0;
    final companions = <ContactsTableCompanion>[];
    for (final row in data) {
      if (row.isEmpty) continue;
      final phone = _normalizePhone(row[phoneColumnIndex]?.toString().trim() ?? '');
      if (phone.isEmpty) continue;
      final name = nameColumnIndex < row.length
          ? row[nameColumnIndex]?.toString().trim() ?? phone
          : phone;
      companions.add(ContactsTableCompanion.insert(name: name, phone: phone));
    }

    for (var i = 0; i < companions.length; i += 500) {
      final batch = companions.sublist(i, (i + 500).clamp(0, companions.length));
      await _dao.bulkInsert(batch);
      imported += batch.length;
    }

    final duplicates = (data.length - imported).clamp(0, data.length);
    return (imported: imported, duplicates: duplicates);
  }

  // ── VCF Import ─────────────────────────────────────────────────────────────

  /// Analisa e importa contatos de um arquivo VCF (vCard 2.1 / 3.0 / 4.0).
  /// Não requer dependências externas — parser 100% Dart.
  Future<({int imported, int duplicates})> importFromVcf(
    String vcfContent,
  ) async {
    final contacts = VcfParser.parse(vcfContent);
    if (contacts.isEmpty) return (imported: 0, duplicates: 0);

    final companions = contacts
        .where((c) => c.phone.isNotEmpty)
        .map((c) => ContactsTableCompanion.insert(
              name: c.name,
              phone: _normalizePhone(c.phone),
              email: Value(c.email),
            ))
        .toList();

    int imported = 0;
    for (var i = 0; i < companions.length; i += 500) {
      final batch = companions.sublist(i, (i + 500).clamp(0, companions.length));
      await _dao.bulkInsert(batch);
      imported += batch.length;
    }

    final duplicates = (contacts.length - imported).clamp(0, contacts.length);
    return (imported: imported, duplicates: duplicates);
  }

  // ── Device contacts import ────────────────────────────────────────────────

  /// Solicita permissão de leitura da agenda. Retorna true se concedida.
  Future<bool> requestContactsPermission() =>
      fc.FlutterContacts.requestPermission(readonly: true);

  /// Carrega todos os contatos do dispositivo com telefone e e-mail.
  Future<List<fc.Contact>> getDeviceContacts() =>
      fc.FlutterContacts.getContacts(withProperties: true, sorted: true);

  /// Importa a lista de contatos do dispositivo para o banco local.
  /// Duplicatas (mesmo número) são silenciosamente ignoradas pelo DAO.
  Future<({int imported, int skipped, int duplicates})> importFromDevice(
    List<fc.Contact> deviceContacts,
  ) async {
    final companions = <ContactsTableCompanion>[];
    int skipped = 0;

    for (final c in deviceContacts) {
      if (c.phones.isEmpty) { skipped++; continue; }
      final phone = _normalizePhone(c.phones.first.number);
      if (phone.isEmpty) { skipped++; continue; }
      final name  = c.displayName.isNotEmpty ? c.displayName : phone;
      final email = c.emails.isNotEmpty ? c.emails.first.address : null;
      companions.add(ContactsTableCompanion.insert(
        name:  name,
        phone: phone,
        email: Value(email),
      ));
    }

    int imported = 0;
    for (var i = 0; i < companions.length; i += 500) {
      final batch = companions.sublist(i, (i + 500).clamp(0, companions.length));
      await _dao.bulkInsert(batch);
      imported += batch.length;
    }

    final withPhone  = deviceContacts.length - skipped;
    final duplicates = (withPhone - imported).clamp(0, withPhone);
    return (imported: imported, skipped: skipped, duplicates: duplicates);
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

  // ── Internals ─────────────────────────────────────────────────────────────

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return phone.trim();
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('55') && digits.length >= 12) return '+$digits';
    if (digits.length == 11 || digits.length == 10) return '+55$digits';
    return digits;
  }
}
