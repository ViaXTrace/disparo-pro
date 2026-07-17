import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TemplateFormScreen extends ConsumerStatefulWidget {
  final String? id;
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

  bool get isEdit => widget.id != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              maxLines: 6,
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['{{nome}}', '{{telefone}}', '{{valor}}', '{{data}}']
                  .map((v) => ActionChip(
                        label: Text(v),
                        onPressed: () {
                          final sel = _bodyCtrl.selection;
                          _bodyCtrl.text = _bodyCtrl.text.replaceRange(
                            sel.start < 0 ? _bodyCtrl.text.length : sel.start,
                            sel.end < 0 ? _bodyCtrl.text.length : sel.end,
                            v,
                          );
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Salvando...' : 'Salvar template'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 300)); // TODO: repo
    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/templates');
  }
}
