import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../templates/providers/templates_providers.dart';

class TemplateFormScreen extends ConsumerStatefulWidget {
  final int? id;
  const TemplateFormScreen({super.key, this.id});

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _channel = 'all';
  bool _saving = false;
  bool _loaded = false;

  bool get isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final t = await ref.read(templateRepositoryProvider).getById(widget.id!);
    if (t == null || !mounted) return;
    setState(() {
      _nameCtrl.text = t.name;
      _bodyCtrl.text = t.body;
      _channel = t.channel;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  List<String> get _variables =>
      ref.read(templateRepositoryProvider).extractVariables(_bodyCtrl.text);

  @override
  Widget build(BuildContext context) {
    if (isEdit && !_loaded) {
      return Scaffold(appBar: AppBar(title: const Text('Carregando…')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar Template' : 'Novo Template')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome do template'),
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _channel,
              decoration: const InputDecoration(labelText: 'Canal'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Todos os canais')),
                DropdownMenuItem(value: 'sms', child: Text('SMS')),
                DropdownMenuItem(value: 'rcs', child: Text('RCS')),
                DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
              ],
              onChanged: (v) => setState(() => _channel = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Corpo da mensagem',
                hintText: 'Use {{nome}}, {{valor}} para variáveis dinâmicas',
                alignLabelWithHint: true,
              ),
              maxLines: 7,
              onChanged: (_) => setState(() {}),
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            // Character count for SMS channel
            if (_channel == 'sms' || _channel == 'all')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ValueListenableBuilder(
                  valueListenable: _bodyCtrl,
                  builder: (_, v, __) {
                    final len = v.text.length;
                    return Text('$len caracteres · ${(len / 160).ceil()} SMS', style: TextStyle(fontSize: 11, color: len > 160 ? Colors.orange : Colors.grey));
                  },
                ),
              ),
            const SizedBox(height: 12),

            // Variable chips
            Text('Inserir variável', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ['nome', 'telefone', 'valor', 'data', 'empresa', 'codigo']
                  .map((v) => ActionChip(
                        label: Text('{{$v}}', style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          final sel = _bodyCtrl.selection;
                          final text = _bodyCtrl.text;
                          final start = sel.start < 0 ? text.length : sel.start;
                          final end = sel.end < 0 ? text.length : sel.end;
                          _bodyCtrl.value = TextEditingValue(
                            text: text.replaceRange(start, end, '{{$v}}'),
                            selection: TextSelection.collapsed(offset: start + '{{$v}}'.length),
                          );
                          setState(() {});
                        },
                      ))
                  .toList(),
            ),

            // Detected variables preview
            if (_variables.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Variáveis detectadas:', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, children: _variables.map((v) => Chip(
                      label: Text('{{$v}}', style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    )).toList()),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Salvando…' : (isEdit ? 'Atualizar template' : 'Salvar template')),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(templateRepositoryProvider);
      final vars = _variables;
      if (isEdit) {
        final existing = await repo.getById(widget.id!);
        if (existing != null) {
          await repo.update(existing,
            name: _nameCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            channel: _channel,
            variables: vars,
          );
        }
      } else {
        await repo.create(
          name: _nameCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          channel: _channel,
          variables: vars,
        );
      }
      if (mounted) context.go('/templates');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
