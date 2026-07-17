import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/gateway/gateway_registry.dart';

class ProviderFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const ProviderFormScreen({super.key, this.id});

  @override
  ConsumerState<ProviderFormScreen> createState() => _ProviderFormScreenState();
}

class _ProviderFormScreenState extends ConsumerState<ProviderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final Map<String, TextEditingController> _credCtrls = {};

  String? _selectedType;
  bool _isDefault = false;
  bool _saving = false;
  bool _validating = false;
  bool? _validResult;

  bool get isEdit => widget.id != null;

  ProviderMeta? get _meta =>
      _selectedType != null ? GatewayRegistry.metadata[_selectedType] : null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _credCtrls.values) { c.dispose(); }
    super.dispose();
  }

  void _onTypeChanged(String? type) {
    setState(() {
      _selectedType = type;
      _validResult = null;
      _credCtrls.clear();
      if (type != null) {
        final meta = GatewayRegistry.metadata[type]!;
        for (final f in meta.credentialFields) {
          _credCtrls[f.key] = TextEditingController();
        }
        _nameCtrl.text = meta.label;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar Provedor' : 'Adicionar Provedor')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Tipo de provedor'),
              hint: const Text('Selecione o provedor'),
              items: GatewayRegistry.allProviders
                  .map((m) => DropdownMenuItem(value: m.type, child: Text(m.label)))
                  .toList(),
              onChanged: _onTypeChanged,
              validator: (v) => v == null ? 'Selecione um provedor' : null,
            ),
            if (_meta != null) ...[
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_meta!.description, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome de exibição'),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Text('Credenciais', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey)),
              const SizedBox(height: 8),
              ..._meta!.credentialFields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _credCtrls[field.key],
                  decoration: InputDecoration(
                    labelText: field.label,
                    hintText: field.hint,
                    suffixIcon: field.secret ? const Icon(Icons.lock_outline, size: 16) : null,
                  ),
                  obscureText: field.secret,
                  validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                ),
              )),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Definir como provedor padrão'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _validating ? null : _validate,
                icon: _validating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_validResult == null ? Icons.check_circle_outline : (_validResult! ? Icons.check_circle : Icons.cancel), color: _validResult == null ? null : (_validResult! ? Colors.green : Colors.red)),
                label: Text(_validating ? 'Validando...' : (_validResult == null ? 'Testar credenciais' : (_validResult! ? 'Credenciais válidas!' : 'Credenciais inválidas'))),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving || _selectedType == null ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Salvando...' : 'Salvar provedor'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _validating = true; _validResult = null; });
    final creds = {for (final e in _credCtrls.entries) e.key: e.value.text};
    final gw = GatewayRegistry.build(_selectedType!);
    final ok = await gw.validateCredentials(creds);
    if (!mounted) return;
    setState(() { _validating = false; _validResult = ok; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // TODO: persist to DB via repository
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/providers');
  }
}
