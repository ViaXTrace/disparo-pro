import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/contacts_providers.dart';

class ContactImportScreen extends ConsumerStatefulWidget {
  const ContactImportScreen({super.key});

  @override
  ConsumerState<ContactImportScreen> createState() => _ContactImportScreenState();
}

class _ContactImportScreenState extends ConsumerState<ContactImportScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Importar Contatos via CSV')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Step 1 – File picker
          _Step(number: 1, title: 'Selecione o arquivo CSV', child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(_fileName ?? 'Nenhum arquivo selecionado', style: TextStyle(color: _filePath == null ? Colors.grey : null))),
                FilledButton.tonal(onPressed: _pickFile, child: const Text('Escolher arquivo')),
              ]),
              if (_preview != null) ...[
                const SizedBox(height: 12),
                Text('Prévia (${_preview!.length} linhas lidas)', style: const TextStyle(fontWeight: FontWeight.w500)),
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
                      (i) => DataColumn(label: Text('Col ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    rows: _preview!.take(5).map((row) => DataRow(
                      cells: row.map((cell) => DataCell(Text(cell.toString(), overflow: TextOverflow.ellipsis))).toList(),
                    )).toList(),
                  ),
                ),
              ],
            ],
          )),

          const SizedBox(height: 12),

          // Step 2 – Column mapping
          _Step(number: 2, title: 'Mapeie as colunas', child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Primeira linha é cabeçalho'),
                value: _hasHeader,
                onChanged: (v) => setState(() => _hasHeader = v),
              ),
              const Divider(height: 1),
              _ColPicker(label: 'Coluna do telefone (obrigatório)', value: _phoneColumnIndex, onChanged: (v) => setState(() => _phoneColumnIndex = v)),
              _ColPicker(label: 'Coluna do nome', value: _nameColumnIndex, onChanged: (v) => setState(() => _nameColumnIndex = v)),
            ],
          )),

          const SizedBox(height: 12),

          // Step 3 – Import
          _Step(number: 3, title: 'Importe', child: Column(
            children: [
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
                  onPressed: _filePath == null || _importing ? null : _startImport,
                  icon: const Icon(Icons.upload),
                  label: Text(_importing ? 'Importando…' : 'Iniciar importação'),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null) return;
    final content = await File(path).readAsString();
    final lines = content.split('\n').take(6).map((l) => l.split(',')).toList();
    setState(() {
      _filePath = path;
      _fileName = result.files.single.name;
      _preview = lines;
      _imported = null;
      _duplicates = null;
    });
  }

  Future<void> _startImport() async {
    if (_filePath == null) return;
    setState(() { _importing = true; _imported = null; _duplicates = null; });
    try {
      final content = await File(_filePath!).readAsString();
      final repo = ref.read(contactRepositoryProvider);
      final result = await repo.importFromCsv(
        content,
        phoneColumnIndex: _phoneColumnIndex,
        nameColumnIndex: _nameColumnIndex,
        hasHeader: _hasHeader,
      );
      setState(() { _imported = result.imported; _duplicates = result.duplicates; });
      ref.invalidate(contactsStreamProvider);
      ref.invalidate(contactCountProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _importing = false);
    }
  }
}

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
          CircleAvatar(radius: 12, child: Text('$number', style: const TextStyle(fontSize: 12))),
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
  const _ColPicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: const Icon(Icons.remove), onPressed: value > 0 ? () => onChanged(value - 1) : null),
      Text('Col ${value + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
      IconButton(icon: const Icon(Icons.add), onPressed: () => onChanged(value + 1)),
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
        Expanded(child: Text('$imported contatos importados${duplicates > 0 ? ', $duplicates duplicatas ignoradas' : ''}')),
      ]),
    ),
  );
}
