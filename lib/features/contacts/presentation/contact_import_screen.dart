import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vcf_parser.dart';
import '../providers/contacts_providers.dart';

// ═══════════════════════════════════════════════════════════════════
//  ContactImportScreen — suporta CSV e VCF (vCard)
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
    _tab = TabController(length: 2, vsync: this);
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
        title: const Text('Importar Contatos'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.table_chart_outlined), text: 'CSV'),
            Tab(icon: Icon(Icons.contact_phone_outlined), text: 'VCF / vCard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_CsvImportTab(), _VcfImportTab()],
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
