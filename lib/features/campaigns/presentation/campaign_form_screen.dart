import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../campaigns/providers/campaigns_providers.dart';
import '../../contacts/providers/contacts_providers.dart';
import '../../providers/providers/providers_providers.dart';
import '../../templates/providers/templates_providers.dart';

class CampaignFormScreen extends ConsumerStatefulWidget {
  final int? id;
  const CampaignFormScreen({super.key, this.id});

  @override
  ConsumerState<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends ConsumerState<CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  String _channel = 'sms';
  int? _providerId;
  int? _groupId;
  int? _templateId;
  DateTime? _scheduledAt;
  int _batchSize = 50;
  int _delayMs = 500;
  bool _saving = false;
  bool _loaded = false;

  bool get isEdit => widget.id != null;

  // Channel metadata
  static const _channels = [
    ('sms', 'SMS', Color(0xFF10B981)),
    ('rcs', 'RCS', Color(0xFF818CF8)),
    ('whatsapp', 'WhatsApp', Color(0xFF25D366)),
  ];

  @override
  void initState() {
    super.initState();
    if (isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final campaign = await ref.read(campaignRepositoryProvider).getById(widget.id!);
    if (campaign == null || !mounted) return;
    setState(() {
      _nameCtrl.text = campaign.name;
      _bodyCtrl.text = campaign.messageBody;
      _channel = campaign.channel;
      _providerId = campaign.providerId;
      _groupId = campaign.contactGroupId;
      _templateId = campaign.templateId;
      _scheduledAt = campaign.scheduledAt;
      _batchSize = campaign.batchSize;
      _delayMs = campaign.delayBetweenBatchesMs;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final providers = ref.watch(providersStreamProvider);
    final groups = ref.watch(contactGroupsStreamProvider);
    final templates = ref.watch(templatesStreamProvider(_channel));

    if (isEdit && !_loaded) {
      return Scaffold(
        appBar: _buildAppBar(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Bottom padding = MediaQuery.padding.bottom which MainShell injects as
    // 80 + safeArea when nav bar is visible, or just safeArea when it's not.
    final navBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _buildAppBar(isDark),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, navBottom + 16),
          children: [
            // ── Identificação ──────────────────────────────────────────
            _sectionLabel(context, 'Identificação'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome da campanha',
                prefixIcon: Icon(Icons.label_outline, size: 18),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 20),

            // ── Canal de envio ─────────────────────────────────────────
            _sectionLabel(context, 'Canal de envio'),
            _ChannelSelector(
              selected: _channel,
              onChanged: (ch) => setState(() {
                _channel = ch;
                _templateId = null;
              }),
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // ── Provedor ───────────────────────────────────────────────
            _sectionLabel(context, 'Provedor'),
            providers.when(
              data: (list) {
                if (list.isEmpty) {
                  return _NoProviderBanner(onConfigure: () => context.go('/providers/new'));
                }
                return DropdownButtonFormField<int>(
                  value: _providerId,
                  decoration: const InputDecoration(
                    labelText: 'Provedor de envio',
                    prefixIcon: Icon(Icons.dns_outlined, size: 18),
                  ),
                  hint: Text('Selecione', style: GoogleFonts.poppins(fontSize: 14)),
                  items: list.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Row(children: [
                      Icon(Icons.dns_outlined, size: 16, color: AppColors.accentDark),
                      const SizedBox(width: 8),
                      Text(p.name, style: GoogleFonts.poppins(fontSize: 14)),
                      if (p.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentDark.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('Padrão', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.accentDark)),
                        ),
                      ],
                    ]),
                  )).toList(),
                  onChanged: (v) => setState(() => _providerId = v),
                  validator: (v) => v == null ? 'Selecione um provedor' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erro ao carregar provedores'),
            ),
            const SizedBox(height: 20),

            // ── Destinatários ─────────────────────────────────────────
            _sectionLabel(context, 'Destinatários'),
            groups.when(
              data: (list) => DropdownButtonFormField<int>(
                value: _groupId,
                decoration: const InputDecoration(
                  labelText: 'Grupo de contatos',
                  prefixIcon: Icon(Icons.group_outlined, size: 18),
                ),
                hint: Text('Selecione um grupo', style: GoogleFonts.poppins(fontSize: 14)),
                items: list.map((g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(g.name, style: GoogleFonts.poppins(fontSize: 14)),
                )).toList(),
                onChanged: (v) => setState(() => _groupId = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // ── Mensagem ──────────────────────────────────────────────
            _sectionLabel(context, 'Mensagem'),
            templates.when(
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : DropdownButtonFormField<int>(
                      value: _templateId,
                      decoration: const InputDecoration(
                        labelText: 'Usar template (opcional)',
                        prefixIcon: Icon(Icons.article_outlined, size: 18),
                      ),
                      hint: Text('Nenhum', style: GoogleFonts.poppins(fontSize: 14)),
                      items: [
                        DropdownMenuItem(value: null, child: Text('Sem template', style: GoogleFonts.poppins(fontSize: 14))),
                        ...list.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, style: GoogleFonts.poppins(fontSize: 14)))),
                      ],
                      onChanged: (v) {
                        setState(() => _templateId = v);
                        if (v != null) {
                          final matches = list.where((t) => t.id == v);
                          if (matches.isNotEmpty) _bodyCtrl.text = matches.first.body;
                        }
                      },
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                hintText: 'Corpo da mensagem\nUse {{nome}}, {{valor}} para personalizar…',
                alignLabelWithHint: true,
              ),
              style: GoogleFonts.poppins(fontSize: 14, height: 1.55),
              maxLines: 5,
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 6),
            // Character counter
            if (_channel == 'sms')
              ValueListenableBuilder(
                valueListenable: _bodyCtrl,
                builder: (_, v, __) {
                  final len = v.text.length;
                  final parts = len == 0 ? 0 : (len / 160).ceil();
                  final warn = len > 160;
                  return Row(children: [
                    Icon(Icons.text_fields, size: 12,
                        color: warn ? AppColors.amberDark : AppColors.textMutedDark),
                    const SizedBox(width: 4),
                    Text('$len caracteres · $parts SMS',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: warn ? AppColors.amberDark : AppColors.textMutedDark,
                        )),
                  ]);
                },
              ),
            const SizedBox(height: 20),

            // ── Agendamento ───────────────────────────────────────────
            _sectionLabel(context, 'Agendamento'),
            _ScheduleTile(
              isDark: isDark,
              scheduledAt: _scheduledAt,
              onClear: () => setState(() => _scheduledAt = null),
              onPick: _pickSchedule,
            ),
            const SizedBox(height: 20),

            // ── Velocidade ────────────────────────────────────────────
            _sectionLabel(context, 'Velocidade de envio'),
            _SpeedCard(
              isDark: isDark,
              batchSize: _batchSize,
              delayMs: _delayMs,
              onBatchChanged: (v) => setState(() => _batchSize = v),
              onDelayChanged: (v) => setState(() => _delayMs = v),
            ),
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
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _saving ? 'Salvando…' : (isEdit ? 'Atualizar campanha' : 'Salvar campanha'),
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

  // ── Sub-widgets ─────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark) => AppBar(
    backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
    surfaceTintColor: Colors.transparent,
    title: Text(
      isEdit ? 'Editar Campanha' : 'Nova Campanha',
      style: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5,
        color: isDark ? AppColors.textDark : AppColors.textLight,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
          color: isDark ? AppColors.textDark : AppColors.textLight),
      onPressed: () => context.go('/campaigns'),
    ),
  );

  Widget _sectionLabel(BuildContext context, String text) => Padding(
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

  String _fmtDt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(campaignRepositoryProvider);
      if (isEdit) {
        final existing = await repo.getById(widget.id!);
        if (existing != null) {
          await repo.update(existing,
            name: _nameCtrl.text.trim(),
            channel: _channel,
            messageBody: _bodyCtrl.text.trim(),
            providerId: _providerId,
            contactGroupId: _groupId,
            templateId: _templateId,
            scheduledAt: _scheduledAt,
            batchSize: _batchSize,
            delayBetweenBatchesMs: _delayMs,
          );
        }
        if (mounted) context.go('/campaigns/${widget.id}');
      } else {
        final campaign = await repo.create(
          name: _nameCtrl.text.trim(),
          channel: _channel,
          messageBody: _bodyCtrl.text.trim(),
          providerId: _providerId!,
          contactGroupId: _groupId,
          templateId: _templateId,
          scheduledAt: _scheduledAt,
          batchSize: _batchSize,
          delayBetweenBatchesMs: _delayMs,
        );
        if (_scheduledAt != null) {
          await repo.schedule(campaign.id, _scheduledAt!);
        }
        if (mounted) context.go('/campaigns/${campaign.id}');
      }
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

// ═══════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

class _ChannelSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _ChannelSelector({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  static const _opts = [
    ('sms',      'SMS',      Color(0xFF10B981), Icons.sms_outlined),
    ('rcs',      'RCS',      Color(0xFF818CF8), Icons.chat_outlined),
    ('whatsapp', 'WhatsApp', Color(0xFF25D366), Icons.message_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _opts.map((o) {
        final (value, label, color, icon) = o;
        final active = selected == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active
                      ? color.withOpacity(0.14)
                      : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? color : AppColors.borderDark,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18,
                        color: active ? color : AppColors.textMutedDark),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? color : AppColors.textMutedDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NoProviderBanner extends StatelessWidget {
  final VoidCallback onConfigure;
  const _NoProviderBanner({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redDark.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.redDark.withOpacity(0.30)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, color: AppColors.redDark, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Nenhum provedor configurado',
            style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.redDark,
            ),
          ),
        ),
        GestureDetector(
          onTap: onConfigure,
          child: Text(
            'Configurar',
            style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.redDark,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ]),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final bool isDark;
  final DateTime? scheduledAt;
  final VoidCallback onClear;
  final VoidCallback onPick;

  const _ScheduleTile({
    required this.isDark,
    required this.scheduledAt,
    required this.onClear,
    required this.onPick,
  });

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(children: [
        Icon(
          scheduledAt == null ? Icons.bolt_rounded : Icons.schedule_rounded,
          size: 18,
          color: scheduledAt == null ? AppColors.accentDark : AppColors.amberDark,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Disparar em',
              style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            Text(
              scheduledAt == null ? 'Imediatamente após salvar' : _fmt(scheduledAt!),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSubDark,
              ),
            ),
          ]),
        ),
        if (scheduledAt != null)
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.textMutedDark,
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        const SizedBox(width: 6),
        OutlinedButton(
          onPressed: onPick,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentDark,
            side: const BorderSide(color: AppColors.accentDark),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Agendar'),
        ),
      ]),
    );
  }
}

class _SpeedCard extends StatelessWidget {
  final bool isDark;
  final int batchSize;
  final int delayMs;
  final ValueChanged<int> onBatchChanged;
  final ValueChanged<int> onDelayChanged;

  const _SpeedCard({
    required this.isDark,
    required this.batchSize,
    required this.delayMs,
    required this.onBatchChanged,
    required this.onDelayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SpeedRow(
          icon: Icons.stacked_line_chart_rounded,
          label: 'Lote',
          value: '$batchSize msg/vez',
          slider: Slider(
            value: batchSize.toDouble(),
            min: 10, max: 500, divisions: 49,
            activeColor: AppColors.accentDark,
            inactiveColor: AppColors.borderDark,
            onChanged: (v) => onBatchChanged(v.round()),
          ),
        ),
        const Divider(color: AppColors.borderDark, height: 1),
        _SpeedRow(
          icon: Icons.timer_outlined,
          label: 'Intervalo',
          value: '${delayMs}ms',
          slider: Slider(
            value: delayMs.toDouble(),
            min: 100, max: 5000, divisions: 49,
            activeColor: AppColors.accentDark,
            inactiveColor: AppColors.borderDark,
            onChanged: (v) => onDelayChanged(v.round()),
          ),
        ),
      ]),
    );
  }
}

class _SpeedRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Widget slider;
  const _SpeedRow({required this.icon, required this.label, required this.value, required this.slider});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, size: 15, color: AppColors.textMutedDark),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSubDark)),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentDark)),
        ]),
      ),
      slider,
    ]);
  }
}
