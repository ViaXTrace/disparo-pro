import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/gateway/gateway_registry.dart';
import '../../../core/theme/app_theme.dart';

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
    for (final c in _credCtrls.values) {
      c.dispose();
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isEdit ? 'Editar Provedor' : 'Adicionar Provedor',
          style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
              color: isDark ? AppColors.textDark : AppColors.textLight),
          onPressed: () => context.go('/providers'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, navBottom + 16),
          children: [
            // ── Tipo ───────────────────────────────────────────────────
            _sectionLabel('Provedor'),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de provedor',
                prefixIcon: Icon(Icons.dns_outlined, size: 18),
              ),
              hint: Text('Selecione o provedor',
                  style: GoogleFonts.poppins(fontSize: 14)),
              style: GoogleFonts.poppins(fontSize: 14),
              items: GatewayRegistry.allProviders
                  .map((m) => DropdownMenuItem(
                        value: m.type,
                        child: Text(m.label,
                            style: GoogleFonts.poppins(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: _onTypeChanged,
              validator: (v) => v == null ? 'Selecione um provedor' : null,
            ),

            // ── Info do provedor ───────────────────────────────────────
            if (_meta != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentDark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accentDark.withOpacity(0.20)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.accentDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _meta!.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSubDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Nome de exibição ────────────────────────────────────
              _sectionLabel('Identificação'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome de exibição',
                  prefixIcon: Icon(Icons.label_outline, size: 18),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 20),

              // ── Credenciais ─────────────────────────────────────────
              _sectionLabel('Credenciais'),
              ..._meta!.credentialFields.map((field) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _credCtrls[field.key],
                      decoration: InputDecoration(
                        labelText: field.label,
                        hintText: field.hint,
                        prefixIcon: Icon(
                          field.secret
                              ? Icons.lock_outline_rounded
                              : Icons.key_outlined,
                          size: 18,
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      obscureText: field.secret,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Obrigatório' : null,
                    ),
                  )),
              const SizedBox(height: 4),

              // ── Padrão toggle ───────────────────────────────────────
              _DefaultToggle(
                isDark: isDark,
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 16),

              // ── Testar credenciais ──────────────────────────────────
              _TestButton(
                validating: _validating,
                result: _validResult,
                onTest: _validate,
              ),
            ],

            const SizedBox(height: 24),

            // ── Salvar ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving || _selectedType == null ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _saving ? 'Salvando…' : 'Salvar provedor',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textMutedDark,
      ),
    ),
  );

  Future<void> _validate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _validating = true;
      _validResult = null;
    });
    final creds = {for (final e in _credCtrls.entries) e.key: e.value.text};
    final gw = GatewayRegistry.build(_selectedType!);
    final ok = await gw.validateCredentials(creds);
    if (!mounted) return;
    setState(() {
      _validating = false;
      _validResult = ok;
    });
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

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _DefaultToggle extends StatelessWidget {
  final bool isDark, value;
  final ValueChanged<bool> onChanged;

  const _DefaultToggle({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(
          'Definir como provedor padrão',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Usado automaticamente ao criar campanhas',
          style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textMutedDark),
        ),
        value: value,
        activeColor: AppColors.accentDark,
        onChanged: onChanged,
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final bool validating;
  final bool? result;
  final VoidCallback onTest;

  const _TestButton({
    required this.validating,
    required this.result,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    if (validating) {
      color = AppColors.accentDark;
      icon = Icons.sync_rounded;
      label = 'Validando…';
    } else if (result == null) {
      color = AppColors.accentDark;
      icon = Icons.check_circle_outline;
      label = 'Testar credenciais';
    } else if (result!) {
      color = AppColors.greenDark;
      icon = Icons.check_circle;
      label = 'Credenciais válidas!';
    } else {
      color = AppColors.redDark;
      icon = Icons.cancel;
      label = 'Credenciais inválidas';
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: validating ? null : onTest,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        ),
        icon: validating
            ? SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: color))
            : Icon(icon, size: 18),
        label: Text(label,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }
}
