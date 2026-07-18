import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../data/contact_repository.dart';
import '../data/vcf_parser.dart';
import '../providers/contacts_providers.dart';

// ═══════════════════════════════════════════════════════════════════
//  ContactImportScreen — CSV · VCF · Agenda do Dispositivo
// ═══════════════════════════════════════════════════════════════════

class ContactImportScreen extends ConsumerStatefulWidget {
  const ContactImportScreen({super.key});

  @override
  ConsumerState<ContactImportScreen> createState() => _ContactImportScreenState();
}

class _ContactImportScreenState extends ConsumerState<ContactImportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Importar Contatos', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.table_chart_outlined),    text: 'CSV'),
            Tab(icon: Icon(Icons.contact_phone_outlined),  text: 'VCF / vCard'),
            Tab(icon: Icon(Icons.contacts_rounded),        text: 'Agenda'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_CsvImportTab(), _VcfImportTab(), _DeviceContactsTab()],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// CSV Tab
// ───────────────────────────────────────────────────────────────────

class _CsvImportTab extends ConsumerStatefulWidget {
  const _CsvImportTab();

  @override
  ConsumerState<_CsvImportTab> createState() => _CsvImportTabState();
}

class _CsvImportTabState extends ConsumerState<_CsvImportTab> {
  String? _filePath;
  String? _fileName;
  List<List<dynamic>>? _preview;

  bool _hasHeader = true;
  int _phoneColumnIndex = 0;
  int _nameColumnIndex = 1;

  bool _importing = false;
  int? _imported;
  int? _duplicates;

  @override
  Widget build(BuildContext context) {
    final navBottom = MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, navBottom + 16),
      children: [
        _Step(
          number: 1,
          title: 'Selecione o arquivo CSV',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  _fileName ?? 'Nenhum arquivo selecionado',
                  style: TextStyle(color: _filePath == null ? Colors.grey : null),
                ),
              ),
              FilledButton.tonal(onPressed: _pickFile, child: const Text('Escolher arquivo')),
            ]),
            if (_preview != null) ...[
              const SizedBox(height: 12),
              Text('Prévia (${_preview!.length} linhas)',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowHeight: 36,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 40,
                  columns: List.generate(
                    _preview!.first.length,
                    (i) => DataColumn(
                        label: Text('Col ${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  rows: _preview!
                      .take(5)
                      .map((row) => DataRow(
                            cells: row
                                .map((c) =>
                                    DataCell(Text(c.toString(), overflow: TextOverflow.ellipsis)))
                                .toList(),
                          ))
                      .toList(),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        _Step(
          number: 2,
          title: 'Mapeie as colunas',
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Primeira linha é cabeçalho'),
              value: _hasHeader,
              onChanged: (v) => setState(() => _hasHeader = v),
            ),
            const Divider(height: 1),
            _ColPicker(
              label: 'Coluna do telefone (obrigatório)',
              value: _phoneColumnIndex,
              onChanged: (v) => setState(() => _phoneColumnIndex = v),
            ),
            _ColPicker(
              label: 'Coluna do nome',
              value: _nameColumnIndex,
              onChanged: (v) => setState(() => _nameColumnIndex = v),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _Step(
          number: 3,
          title: 'Importe',
          child: Column(children: [
            if (_importing) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Importando contatos…', style: TextStyle(color: Colors.grey)),
            ] else if (_imported != null) ...[
              _ResultBanner(imported: _imported!, duplicates: _duplicates ?? 0),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text('Importar CSV'),
                onPressed: _filePath == null || _importing ? null : _import,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'txt']);
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null) return;
    final content = await File(path).readAsString();
    final rows = content.split('\n').take(6).map((l) => l.split(',')).toList();
    setState(() {
      _filePath = path;
      _fileName = result.files.single.name;
      _preview = rows.cast<List<dynamic>>();
      _imported = null;
    });
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final content = await File(_filePath!).readAsString();
      final repo = ref.read(contactRepositoryProvider);
      final result = await repo.importFromCsv(
        content,
        phoneColumnIndex: _phoneColumnIndex,
        nameColumnIndex: _nameColumnIndex,
        hasHeader: _hasHeader,
      );
      setState(() {
        _imported = result.imported;
        _duplicates = result.duplicates;
      });
    } finally {
      setState(() => _importing = false);
    }
  }
}

// ───────────────────────────────────────────────────────────────────
// VCF Tab
// ───────────────────────────────────────────────────────────────────

class _VcfImportTab extends ConsumerStatefulWidget {
  const _VcfImportTab();

  @override
  ConsumerState<_VcfImportTab> createState() => _VcfImportTabState();
}

class _VcfImportTabState extends ConsumerState<_VcfImportTab> {
  String? _filePath;
  String? _fileName;
  List<VcfContact>? _contacts;

  bool _importing = false;
  int? _imported;
  int? _duplicates;

  @override
  Widget build(BuildContext context) {
    final navBottom = MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, navBottom + 16),
      children: [
        // Info banner
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Importe contatos exportados da agenda do celular, Outlook, '
                  'Google Contacts ou qualquer app que gere arquivos .vcf. '
                  'Suporta vCard 2.1, 3.0 e 4.0 — incluindo arquivos com múltiplos contatos.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ]),
          ),
        ),

        // Step 1 – pick file
        _Step(
          number: 1,
          title: 'Selecione o arquivo VCF',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  _fileName ?? 'Nenhum arquivo selecionado',
                  style: TextStyle(color: _filePath == null ? Colors.grey : null),
                ),
              ),
              FilledButton.tonal(onPressed: _pickFile, child: const Text('Escolher arquivo')),
            ]),
            if (_contacts != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.contact_phone, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${_contacts!.length} contato${_contacts!.length != 1 ? "s" : ""} encontrado${_contacts!.length != 1 ? "s" : ""}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              ..._contacts!.take(10).map((c) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 14)),
                    ),
                    title: Text(c.name, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(c.phone, style: const TextStyle(fontSize: 12)),
                    trailing: c.email != null
                        ? const Tooltip(
                            message: 'Tem e-mail',
                            child: Icon(Icons.email_outlined, size: 16))
                        : null,
                  )),
              if ((_contacts?.length ?? 0) > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+ ${_contacts!.length - 10} contatos não exibidos…',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
            ],
          ]),
        ),
        const SizedBox(height: 12),

        // Step 2 – import
        _Step(
          number: 2,
          title: 'Importe',
          child: Column(children: [
            if (_importing) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Importando contatos…', style: TextStyle(color: Colors.grey)),
            ] else if (_imported != null) ...[
              _ResultBanner(imported: _imported!, duplicates: _duplicates ?? 0),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.contact_phone),
                label: const Text('Importar VCF'),
                onPressed:
                    (_filePath == null || _importing || (_contacts?.isEmpty ?? true)) ? null : _import,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['vcf', 'vcard']);
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null) return;
    final content = await File(path).readAsString();
    final contacts = VcfParser.parse(content);
    setState(() {
      _filePath = path;
      _fileName = result.files.single.name;
      _contacts = contacts;
      _imported = null;
    });
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final content = await File(_filePath!).readAsString();
      final repo = ref.read(contactRepositoryProvider);
      final result = await repo.importFromVcf(content);
      setState(() {
        _imported = result.imported;
        _duplicates = result.duplicates;
      });
    } finally {
      setState(() => _importing = false);
    }
  }
}

// ───────────────────────────────────────────────────────────────────
// Aba — Agenda do Dispositivo
// ───────────────────────────────────────────────────────────────────

// Phases of the device-contacts tab state machine.
enum _Phase { checking, permRequired, permDenied, loading, ready, importing, done }

class _DeviceContactsTab extends ConsumerStatefulWidget {
  const _DeviceContactsTab();

  @override
  ConsumerState<_DeviceContactsTab> createState() => _DeviceContactsTabState();
}

class _DeviceContactsTabState extends ConsumerState<_DeviceContactsTab> {
  _Phase _phase = _Phase.checking;

  // Contact list — loaded without properties (names + IDs only).
  List<fc.Contact> _all      = [];
  List<fc.Contact> _filtered = [];

  // Selection state.
  final Set<String> _selected = {};

  // Search — debounced so typing over a million-row list stays smooth.
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  // Import stream.
  StreamSubscription<DevImportProgress>? _importSub;
  DevImportProgress? _progress;
  int _importTotal = 0; // snapshot of selected.length before clearing

  // ── Lifecycle ─────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Check permission silently — no dialog, no re-ask after first grant.
    _checkPermSilently();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _importSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Permission ────────────────────────────────────────────────────

  /// Reads the OS permission status without prompting the user.
  /// If already granted → loads immediately.
  Future<void> _checkPermSilently() async {
    final granted =
        await ref.read(contactRepositoryProvider).isContactsPermissionGranted();
    if (!mounted) return;
    if (granted) {
      _load();
    } else {
      setState(() => _phase = _Phase.permRequired);
    }
  }

  /// Shows the OS permission dialog. Navigates to load or denied gate.
  Future<void> _requestAndLoad() async {
    setState(() => _phase = _Phase.loading);
    final granted =
        await ref.read(contactRepositoryProvider).requestContactsPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _phase = _Phase.permDenied);
      return;
    }
    _load();
  }

  // ── Load ──────────────────────────────────────────────────────────

  /// Fetches IDs + display names only — fast even with 1 M contacts.
  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    final contacts =
        await ref.read(contactRepositoryProvider).getDeviceContacts();
    if (!mounted) return;
    setState(() {
      _all      = contacts;
      _filtered = contacts;
      _phase    = _Phase.ready;
    });
  }

  // ── Search ────────────────────────────────────────────────────────

  void _onSearch(String q) {
    _debounce?.cancel();
    if (q.isEmpty) {
      setState(() => _filtered = _all);
      return;
    }
    // Debounce 280 ms — avoids filtering on every keystroke in huge lists.
    _debounce = Timer(const Duration(milliseconds: 280), () {
      final lower   = q.toLowerCase();
      final results = _all
          .where((c) => c.displayName.toLowerCase().contains(lower))
          .toList();
      if (mounted) setState(() => _filtered = results);
    });
  }

  // ── Selection ─────────────────────────────────────────────────────

  void _toggleAll() => setState(() {
        if (_selected.length == _filtered.length) {
          _selected.clear();
        } else {
          _selected.addAll(_filtered.map((c) => c.id));
        }
      });

  // ── Import ────────────────────────────────────────────────────────

  void _startImport() {
    final ids    = _selected.toList();
    _importTotal = ids.length;

    setState(() {
      _phase    = _Phase.importing;
      _progress = DevImportProgress(processed: 0, total: _importTotal, imported: 0);
      _selected.clear();
    });

    _importSub = ref
        .read(contactRepositoryProvider)
        .importContactsByIds(ids)
        .listen(
          (p) { if (mounted) setState(() => _progress = p); },
          onDone: () {
            if (!mounted) return;
            ref.invalidate(contactCountProvider);
            setState(() => _phase = _Phase.done);
          },
          onError: (_) {
            if (mounted) setState(() => _phase = _Phase.ready);
          },
          cancelOnError: true,
        );
  }

  /// Cancels the running import mid-stream — safe at any point.
  void _cancelImport() {
    _importSub?.cancel();
    _importSub = null;
    if (mounted) setState(() { _phase = _Phase.ready; _progress = null; });
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = Theme.of(context).colorScheme.primary;
    final muted   = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final navPad  = MediaQuery.of(context).padding.bottom;
    final border  = isDark ? AppColors.borderDark : AppColors.borderLight;

    switch (_phase) {
      // ── Verification / loading ────────────────────────────────────
      case _Phase.checking:
      case _Phase.loading:
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(strokeWidth: 2, color: accent),
            const SizedBox(height: 16),
            Text(
              _phase == _Phase.checking
                  ? 'Verificando permissões…'
                  : 'Carregando agenda…',
              style: GoogleFonts.poppins(fontSize: 13, color: muted),
            ),
          ]),
        );

      // ── Permission gates ──────────────────────────────────────────
      case _Phase.permRequired:
        return _PermissionGate(
            isDark: isDark, accent: accent, onRequest: _requestAndLoad);
      case _Phase.permDenied:
        return _PermissionGate(
            isDark: isDark, accent: accent, denied: true,
            onRequest: _requestAndLoad);

      // ── Import in progress ────────────────────────────────────────
      case _Phase.importing:
        final p = _progress!;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, navPad + 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Icon
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.download_rounded, size: 30, color: accent),
            ),
            const SizedBox(height: 20),
            Text('Importando contatos…',
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDark : AppColors.textLight)),
            const SizedBox(height: 20),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: p.total > 0 ? p.pct : null,
                minHeight: 6,
                backgroundColor:
                    isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            const SizedBox(height: 10),

            // Counts
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                '${_fmt(p.processed)} / ${_fmt(p.total)}',
                style: GoogleFonts.dmMono(fontSize: 12, color: muted),
              ),
              Text(
                '${(p.pct * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.dmMono(
                  fontSize: 12, fontWeight: FontWeight.w700, color: accent),
              ),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Importados', style: GoogleFonts.poppins(fontSize: 11, color: muted)),
              Text(_fmt(p.imported),
                  style: GoogleFonts.dmMono(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.greenDark : AppColors.greenLight)),
            ]),
            if (p.noPhone > 0) ...[
              const SizedBox(height: 2),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Sem telefone', style: GoogleFonts.poppins(fontSize: 11, color: muted)),
                Text(_fmt(p.noPhone),
                    style: GoogleFonts.dmMono(fontSize: 12, color: muted)),
              ]),
            ],

            const SizedBox(height: 28),
            TextButton.icon(
              onPressed: _cancelImport,
              icon: const Icon(Icons.close_rounded, size: 15),
              label: Text('Cancelar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(foregroundColor: muted),
            ),
          ]),
        );

      // ── Done ──────────────────────────────────────────────────────
      case _Phase.done:
        final p = _progress!;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, navPad + 24),
          child: Column(children: [
            _BigResultCard(
              isDark: isDark,
              imported:   p.imported,
              duplicates: p.duplicates,
              skipped:    p.noPhone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text('Importar mais',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                onPressed: () =>
                    setState(() { _phase = _Phase.ready; _progress = null; }),
              ),
            ),
          ]),
        );

      // ── Ready: list + search + select ─────────────────────────────
      case _Phase.ready:
        final allSelected  =
            _filtered.isNotEmpty && _selected.length == _filtered.length;
        final someSelected = _selected.isNotEmpty;

        return Column(children: [
          // ── Toolbar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              // Search field
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    style: GoogleFonts.poppins(fontSize: 13,
                        color: isDark ? AppColors.textDark : AppColors.textLight),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome…',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: muted),
                      prefixIcon: Icon(Icons.search_rounded, size: 17, color: muted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Select-all toggle
              GestureDetector(
                onTap: _toggleAll,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: allSelected ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: allSelected ? accent : border),
                  ),
                  child: Text(
                    allSelected ? 'Desmarcar' : 'Todos',
                    style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: allSelected
                          ? Colors.white
                          : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
                    ),
                  ),
                ),
              ),
            ]),
          ),

          // ── Summary strip ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Row(children: [
              Text(
                '${_fmt(_filtered.length)} contato${_filtered.length != 1 ? "s" : ""}'
                '${_all.length != _filtered.length ? " de ${_fmt(_all.length)}" : ""}',
                style: GoogleFonts.poppins(fontSize: 11.5, color: muted),
              ),
              const Spacer(),
              if (someSelected)
                Text(
                  '${_fmt(_selected.length)} selecionado${_selected.length != 1 ? "s" : ""}',
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, fontWeight: FontWeight.w600, color: accent),
                ),
            ]),
          ),

          // ── Virtual list ──────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text('Nenhum resultado',
                        style: GoogleFonts.poppins(fontSize: 13, color: muted)))
                : ListView.builder(
                    // addRepaintBoundaries avoids repainting unchanged tiles
                    // in enormous lists — important for 1 M-row performance.
                    addRepaintBoundaries: true,
                    addAutomaticKeepAlives: false,
                    padding: EdgeInsets.only(
                        bottom: navPad + (someSelected ? 80 : 16)),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final c          = _filtered[i];
                      final checked    = _selected.contains(c.id);
                      final avatarColor = _kDevColors[i % _kDevColors.length];
                      final initials   = _initials(c.displayName);

                      return RepaintBoundary(
                        child: InkWell(
                          onTap: () => setState(() => checked
                              ? _selected.remove(c.id)
                              : _selected.add(c.id)),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: border))),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 11),
                            child: Row(children: [
                              // Avatar
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: avatarColor.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(initials,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13, fontWeight: FontWeight.w800,
                                      color: avatarColor)),
                              ),
                              const SizedBox(width: 12),
                              // Name
                              // (no phone shown — not loaded without properties)
                              Expanded(
                                child: Text(
                                  c.displayName.isNotEmpty ? c.displayName : '—',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5, fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textDark
                                        : AppColors.textLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Checkbox
                              Checkbox(
                                value: checked,
                                onChanged: (_) => setState(() => checked
                                    ? _selected.remove(c.id)
                                    : _selected.add(c.id)),
                                activeColor: accent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                                side: BorderSide(color: border, width: 1.5),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── Sticky import bar ─────────────────────────────────────
          if (someSelected)
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, navPad + 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(top: BorderSide(color: border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 17),
                  label: Text(
                    'Importar ${_fmt(_selected.length)} contato${_selected.length != 1 ? "s" : ""}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  onPressed: _startImport,
                ),
              ),
            ),
        ]);
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _initials(String name) {
  if (name.isEmpty) return '?';
  return name.trim().split(RegExp(r'\s+')).take(2)
      .map((w) => w[0].toUpperCase()).join();
}

String _fmt(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000)    return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
  return v.toString();
}

const _kDevColors = [
  Color(0xFF818CF8), Color(0xFF34D399), Color(0xFFFBBF24),
  Color(0xFFF87171), Color(0xFFA78BFA), Color(0xFF60A5FA),
];

// ── Permission gate ────────────────────────────────────────────────

class _PermissionGate extends StatelessWidget {
  final bool isDark, denied;
  final Color accent;
  final VoidCallback onRequest;
  const _PermissionGate({
    required this.isDark,
    required this.accent,
    required this.onRequest,
    this.denied = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.22)),
            ),
            child: Icon(
              denied ? Icons.no_accounts_rounded : Icons.contacts_rounded,
              size: 34, color: accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            denied ? 'Acesso negado' : 'Ler agenda do dispositivo',
            style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDark : AppColors.textLight,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            denied
                ? 'Permissão negada. Abra as configurações do sistema, '
                  'localize o DyanX e habilite o acesso à Agenda.'
                : 'O DyanX precisa de permissão para ler seus contatos '
                  'e importá-los para campanhas. Nenhum dado é enviado '
                  'para servidores externos.',
            style: GoogleFonts.poppins(
              fontSize: 13, height: 1.55,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(denied ? Icons.settings_rounded : Icons.lock_open_rounded, size: 16),
              label: Text(
                denied ? 'Abrir configurações' : 'Permitir acesso à agenda',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              onPressed: onRequest,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Result card ───────────────────────────────────────────────────

class _BigResultCard extends StatelessWidget {
  final bool isDark;
  final int imported, duplicates, skipped;
  const _BigResultCard({
    required this.isDark,
    required this.imported,
    required this.duplicates,
    required this.skipped,
  });

  @override
  Widget build(BuildContext context) {
    final green  = isDark ? AppColors.greenDark  : AppColors.greenLight;
    final amber  = isDark ? AppColors.amberDark  : AppColors.amberLight;
    final muted  = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: green.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 26, color: green),
        ),
        const SizedBox(height: 14),
        Text('Importação concluída', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        )),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _Stat(value: imported,   label: 'Importados', color: green),
          if (duplicates > 0) _Stat(value: duplicates, label: 'Duplicatas',  color: amber),
          if (skipped > 0)    _Stat(value: skipped,    label: 'Sem telefone', color: muted),
        ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value; final String label; final Color color;
  const _Stat({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text('$value', style: GoogleFonts.dmMono(
      fontSize: 22, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
    const SizedBox(height: 3),
    Text(label, style: GoogleFonts.poppins(
      fontSize: 11, color: color.withOpacity(0.7), fontWeight: FontWeight.w500)),
  ]);
}

// ═══════════════════════════════════════════════════════════════════
//  Widgets compartilhados
// ═══════════════════════════════════════════════════════════════════

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final Widget child;
  const _Step({required this.number, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                  radius: 12,
                  child: Text('$number', style: const TextStyle(fontSize: 12))),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            child,
          ]),
        ),
      );
}

class _ColPicker extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _ColPicker(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              icon: const Icon(Icons.remove),
              onPressed: value > 0 ? () => onChanged(value - 1) : null),
          Text('Col ${value + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
              icon: const Icon(Icons.add), onPressed: () => onChanged(value + 1)),
        ]),
      );
}

class _ResultBanner extends StatelessWidget {
  final int imported, duplicates;
  const _ResultBanner({required this.imported, required this.duplicates});

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.green.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$imported contato${imported != 1 ? "s" : ""} importado${imported != 1 ? "s" : ""}'
                '${duplicates > 0 ? ', $duplicates duplicata${duplicates != 1 ? "s" : ""} ignorada${duplicates != 1 ? "s" : ""}' : ''}',
              ),
            ),
          ]),
        ),
      );
}
