import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isEdit && !_loaded) {
      return Scaffold(
        appBar: _buildAppBar(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final navBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _buildAppBar(isDark),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, navBottom + 16),
          children: [
            // ── Nome ───────────────────────────────────────────────────
            _sectionLabel('Identificação'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do template',
                prefixIcon: Icon(Icons.label_outline, size: 18),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 20),

            // ── Canal ──────────────────────────────────────────────────
            _sectionLabel('Canal'),
            _ChannelDropdown(
              value: _channel,
              isDark: isDark,
              onChanged: (v) => setState(() => _channel = v!),
            ),
            const SizedBox(height: 20),

            // ── Corpo ──────────────────────────────────────────────────
            _sectionLabel('Corpo da mensagem'),
            TextFormField(
              controller: _bodyCtrl,
              decoration: InputDecoration(
                hintText: 'Digite a mensagem…\nUse {{nome}}, {{valor}} para variáveis',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMutedDark,
                  height: 1.6,
                ),
                alignLabelWithHint: true,
              ),
              style: GoogleFonts.poppins(fontSize: 14, height: 1.6),
              maxLines: 7,
              onChanged: (_) => setState(() {}),
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 6),

            // Character count
            if (_channel == 'sms' || _channel == 'all')
              ValueListenableBuilder(
                valueListenable: _bodyCtrl,
                builder: (_, v, __) {
                  final len = v.text.length;
                  final warn = len > 160;
                  return Row(children: [
                    Icon(Icons.text_fields, size: 12,
                        color: warn ? AppColors.amberDark : AppColors.textMutedDark),
                    const SizedBox(width: 4),
                    Text(
                      '$len caracteres · ${len == 0 ? 0 : (len / 160).ceil()} SMS',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: warn ? AppColors.amberDark : AppColors.textMutedDark,
                      ),
                    ),
                  ]);
                },
              ),
            const SizedBox(height: 16),

            // ── Variáveis ──────────────────────────────────────────────
            _sectionLabel('Inserir variável'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['nome', 'telefone', 'valor', 'data', 'empresa', 'codigo']
                  .map((v) => _VarChip(
                        variable: v,
                        isDark: isDark,
                        onTap: () {
                          final sel = _bodyCtrl.selection;
                          final text = _bodyCtrl.text;
                          final start = sel.start < 0 ? text.length : sel.start;
                          final end = sel.end < 0 ? text.length : sel.end;
                          _bodyCtrl.value = TextEditingValue(
                            text: text.replaceRange(start, end, '{{$v}}'),
                            selection: TextSelection.collapsed(
                                offset: start + '{{$v}}'.length),
                          );
                          setState(() {});
                        },
                      ))
                  .toList(),
            ),

            // Detected variables
            if (_variables.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentDark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentDark.withOpacity(0.20)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.auto_fix_high, size: 14, color: AppColors.accentDark),
                    const SizedBox(width: 6),
                    Text(
                      'Variáveis detectadas',
                      style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _variables.map((v) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentDark.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '{{$v}}',
                        style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.accentDark,
                        ),
                      ),
                    )).toList(),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 28),

            // ── Salvar ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _saving ? 'Salvando…' : (isEdit ? 'Atualizar template' : 'Salvar template'),
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

  PreferredSizeWidget _buildAppBar(bool isDark) => AppBar(
    backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
    surfaceTintColor: Colors.transparent,
    title: Text(
      isEdit ? 'Editar Template' : 'Novo Template',
      style: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5,
        color: isDark ? AppColors.textDark : AppColors.textLight,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
          color: isDark ? AppColors.textDark : AppColors.textLight),
      onPressed: () => context.go('/templates'),
    ),
  );

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.redDark),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _ChannelDropdown extends StatelessWidget {
  final String value;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _ChannelDropdown({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.tune_rounded, size: 18),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Todos os canais')),
        DropdownMenuItem(value: 'sms', child: Text('SMS')),
        DropdownMenuItem(value: 'rcs', child: Text('RCS')),
        DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
      ],
      onChanged: onChanged,
    );
  }
}

class _VarChip extends StatelessWidget {
  final String variable;
  final bool isDark;
  final VoidCallback onTap;

  const _VarChip({required this.variable, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface2Dark : AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Text(
          '{{$variable}}',
          style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.accentDark,
          ),
        ),
      ),
    );
  }
}
