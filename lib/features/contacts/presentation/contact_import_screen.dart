import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactImportScreen extends ConsumerStatefulWidget {
  const ContactImportScreen({super.key});

  @override
  ConsumerState<ContactImportScreen> createState() => _ContactImportScreenState();
}

class _ContactImportScreenState extends ConsumerState<ContactImportScreen> {
  String? _selectedFile;
  bool _hasHeader = true;
  int _phoneColumnIndex = 0;
  int _nameColumnIndex = 1;
  bool _importing = false;
  int _imported = 0;
  int _duplicates = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar Contatos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Arquivo CSV', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedFile ?? 'Nenhum arquivo selecionado',
                          style: TextStyle(color: _selectedFile == null ? Colors.grey : null),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: _pickFile,
                        child: const Text('Selecionar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configuração das colunas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('Primeira linha é cabeçalho'),
                    value: _hasHeader,
                    onChanged: (v) => setState(() => _hasHeader = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Coluna do telefone'),
                    trailing: SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: '${_phoneColumnIndex + 1}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(suffixText: 'ª col.'),
                        onChanged: (v) => setState(() => _phoneColumnIndex = (int.tryParse(v) ?? 1) - 1),
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Coluna do nome'),
                    trailing: SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: '${_nameColumnIndex + 1}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(suffixText: 'ª col.'),
                        onChanged: (v) => setState(() => _nameColumnIndex = (int.tryParse(v) ?? 2) - 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_importing) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text('Importando... $_imported importados, $_duplicates duplicatas ignoradas', textAlign: TextAlign.center),
          ],
          if (!_importing && _imported > 0) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.green.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Text('$_imported contatos importados, $_duplicatas duplicatas ignoradas'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _selectedFile == null || _importing ? null : _startImport,
            icon: const Icon(Icons.upload),
            label: const Text('Iniciar importação'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    // TODO: integrate file_picker
    // final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    // if (result != null) setState(() => _selectedFile = result.files.single.path);
  }

  Future<void> _startImport() async {
    setState(() { _importing = true; _imported = 0; _duplicates = 0; });
    // TODO: parse CSV and insert contacts via repository
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _importing = false);
  }
}
