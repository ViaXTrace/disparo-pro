import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/contacts_dao.dart';
import 'vcf_parser.dart';

// ── Progress snapshot emitted during a device-contacts import ─────────────────

class DevImportProgress {
  /// Contacts examined so far (fetched + skipped).
  final int processed;

  /// Total contacts requested for import.
  final int total;

  /// Contacts actually inserted into the local database.
  final int imported;

  /// Contacts skipped because they had no usable phone number.
  final int noPhone;

  /// True on the final emission — import is complete.
  final bool done;

  const DevImportProgress({
    required this.processed,
    required this.total,
    required this.imported,
    this.noPhone = 0,
    this.done    = false,
  });

  /// 0.0 – 1.0 fraction of contacts processed.
  double get pct => total > 0 ? (processed / total).clamp(0.0, 1.0) : 0.0;

  /// Contacts that had a phone but were already in the DB (duplicates).
  int get duplicates => (processed - imported - noPhone).clamp(0, processed);
}

// ─────────────────────────────────────────────────────────────────────────────

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

  /// Checks READ_CONTACTS permission **without** showing a dialog.
  /// Safe to call on every screen open.
  Future<bool> isContactsPermissionGranted() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  /// Shows the OS permission dialog. Returns true if granted.
  Future<bool> requestContactsPermission() =>
      fc.FlutterContacts.requestPermission(readonly: true);

  /// Loads all device contacts **without properties** (names + IDs only).
  ///
  /// This is O(n) in time and ~50 bytes/contact in memory — safe even for
  /// 1 M contacts. Phone/email data is NOT loaded here; it is fetched on
  /// demand during import via [importContactsByIds].
  Future<List<fc.Contact>> getDeviceContacts() =>
      fc.FlutterContacts.getContacts(sorted: true); // withProperties: false

  /// Stream-based, chunked import that handles any list size robustly.
  ///
  /// **Strategy**
  ///   • ≤ [_kBulkThreshold] IDs  → fetch by individual ID in parallel
  ///     batches of [_kParallelFetch] (avoids loading unselected contacts).
  ///   • >  [_kBulkThreshold] IDs → one bulk `getContacts(withProperties)`
  ///     call, then filter + chunk-process in memory (avoids N platform
  ///     round-trips which would be too slow for large selections).
  ///
  /// DB inserts happen in batches of [_kInsertBatch] with
  /// `Future.delayed(Duration.zero)` between each chunk so the UI thread
  /// stays responsive. Cancel the [StreamSubscription] to abort cleanly.
  Stream<DevImportProgress> importContactsByIds(List<String> ids) async* {
    if (ids.isEmpty) {
      yield const DevImportProgress(
          processed: 0, total: 0, imported: 0, done: true);
      return;
    }

    final total   = ids.length;
    int processed = 0;
    int imported  = 0;
    int noPhone   = 0;
    final buffer  = <ContactsTableCompanion>[];

    // Flush buffer to DB in [_kInsertBatch]-sized chunks.
    Future<void> flush() async {
      while (buffer.length >= _kInsertBatch) {
        final batch = buffer.take(_kInsertBatch).toList();
        buffer.removeRange(0, _kInsertBatch);
        await _dao.bulkInsert(batch);
        imported += batch.length;
      }
    }

    void processContact(fc.Contact? c) {
      processed++;
      if (c == null || c.phones.isEmpty) { noPhone++; return; }
      final phone = _normalizePhone(c.phones.first.number);
      if (phone.isEmpty) { noPhone++; return; }
      buffer.add(_toCompanion(c, phone));
    }

    // ── Small / medium selection: fetch by individual ID ─────────────
    if (total <= _kBulkThreshold) {
      for (var i = 0; i < total; i += _kParallelFetch) {
        await Future.delayed(Duration.zero);
        final slice = ids.sublist(i, (i + _kParallelFetch).clamp(0, total));
        final contacts =
            await Future.wait(slice.map(fc.FlutterContacts.getContact));
        for (final c in contacts) processContact(c);
        await flush();
        yield DevImportProgress(
            processed: processed, total: total,
            imported: imported, noPhone: noPhone);
      }
    } else {
      // ── Large selection: single bulk fetch then filter + process ────
      yield DevImportProgress(processed: 0, total: total, imported: 0);
      final allDetailed =
          await fc.FlutterContacts.getContacts(withProperties: true);
      final selectedSet = ids.toSet();
      final matched =
          allDetailed.where((c) => selectedSet.contains(c.id)).toList();

      for (var i = 0; i < matched.length; i += _kInsertBatch) {
        await Future.delayed(Duration.zero);
        final chunk =
            matched.sublist(i, (i + _kInsertBatch).clamp(0, matched.length));
        for (final c in chunk) processContact(c);
        await flush();
        yield DevImportProgress(
            processed: processed, total: total,
            imported: imported, noPhone: noPhone);
      }
    }

    // Final flush of remaining buffer.
    if (buffer.isNotEmpty) {
      await _dao.bulkInsert(buffer);
      imported += buffer.length;
    }

    yield DevImportProgress(
        processed: total, total: total,
        imported: imported, noPhone: noPhone, done: true);
  }

  // Thresholds
  static const int _kBulkThreshold = 500;
  static const int _kParallelFetch = 30;
  static const int _kInsertBatch   = 1000;

  ContactsTableCompanion _toCompanion(fc.Contact c, String phone) =>
      ContactsTableCompanion.insert(
        name:  c.displayName.isNotEmpty ? c.displayName : phone,
        phone: phone,
        email: Value(c.emails.isNotEmpty ? c.emails.first.address : null),
      );

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
