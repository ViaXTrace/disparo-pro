import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final providers = ref.watch(providersStreamProvider);
    final groups = ref.watch(contactGroupsStreamProvider);
    final templates = ref.watch(templatesStreamProvider(_channel));

    if (isEdit && !_loaded) {
      return Scaffold(appBar: AppBar(title: const Text('Carregando…')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar Campanha' : 'Nova Campanha')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            _label(context, 'Identificação'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome da campanha'),
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),

            // Channel
            _label(context, 'Canal de envio'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sms', label: Text('SMS'), icon: Icon(Icons.sms, size: 16)),
                ButtonSegment(value: 'rcs', label: Text('RCS'), icon: Icon(Icons.chat_bubble_outline, size: 16)),
                ButtonSegment(value: 'whatsapp', label: Text('WhatsApp'), icon: Icon(Icons.chat, size: 16)),
              ],
              selected: {_channel},
              onSelectionChanged: (v) => setState(() { _channel = v.first; _templateId = null; }),
            ),
            const SizedBox(height: 16),

            // Provider
            _label(context, 'Provedor'),
            providers.when(
              data: (list) {
                if (list.isEmpty) {
                  return Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber),
                      title: const Text('Nenhum provedor configurado'),
                      trailing: TextButton(onPressed: () => context.go('/providers/new'), child: const Text('Configurar')),
                    ),
                  );
                }
                return DropdownButtonFormField<int>(
                  value: _providerId,
                  decoration: const InputDecoration(labelText: 'Provedor de envio'),
                  hint: const Text('Selecione'),
                  items: list.map((p) => DropdownMenuItem(value: p.id, child: Row(children: [
                    const Icon(Icons.dns, size: 16),
                    const SizedBox(width: 8),
                    Text(p.name),
                    const SizedBox(width: 8),
                    if (p.isDefault) const Chip(label: Text('Padrão', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                  ]))).toList(),
                  onChanged: (v) => setState(() => _providerId = v),
                  validator: (v) => v == null ? 'Selecione um provedor' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erro ao carregar provedores'),
            ),
            const SizedBox(height: 16),

            // Contact group
            _label(context, 'Destinatários'),
            groups.when(
              data: (list) => DropdownButtonFormField<int>(
                value: _groupId,
                decoration: const InputDecoration(labelText: 'Grupo de contatos'),
                hint: const Text('Selecione um grupo'),
                items: list.map((g) => DropdownMenuItem(value: g.id, child: Row(children: [
                  const Icon(Icons.group, size: 16),
                  const SizedBox(width: 8),
                  Text(g.name),
                ]))).toList(),
                onChanged: (v) => setState(() => _groupId = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Template + message
            _label(context, 'Mensagem'),
            templates.when(
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : DropdownButtonFormField<int>(
                      value: _templateId,
                      decoration: const InputDecoration(labelText: 'Usar template (opcional)'),
                      hint: const Text('Nenhum'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sem template')),
                        ...list.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                      ],
                      onChanged: (v) {
                        setState(() => _templateId = v);
                        if (v != null) {
                          final t = (list as List).firstWhere((t) => t.id == v, orElse: () => null);
                          if (t != null) _bodyCtrl.text = t.body;
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
                labelText: 'Corpo da mensagem',
                hintText: 'Use {{nome}}, {{valor}} para personalizar',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 4),
            // Character counter for SMS
            if (_channel == 'sms') ValueListenableBuilder(
              valueListenable: _bodyCtrl,
              builder: (_, v, __) {
                final len = v.text.length;
                final parts = (len / 160).ceil();
                return Text('$len caracteres · $parts SMS', style: TextStyle(fontSize: 11, color: len > 160 ? Colors.orange : Colors.grey));
              },
            ),
            const SizedBox(height: 16),

            // Schedule
            _label(context, 'Agendamento'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disparar em'),
              subtitle: Text(_scheduledAt == null
                  ? 'Imediatamente após salvar'
                  : _fmtDt(_scheduledAt!)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_scheduledAt != null)
                  IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _scheduledAt = null)),
                FilledButton.tonal(onPressed: _pickSchedule, child: const Text('Agendar')),
              ]),
            ),
            const SizedBox(height: 16),

            // Speed
            _label(context, 'Velocidade de envio'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Lote: $_batchSize mensagens por vez'),
              subtitle: Slider(
                value: _batchSize.toDouble(), min: 10, max: 500, divisions: 49,
                label: '$_batchSize',
                onChanged: (v) => setState(() => _batchSize = v.round()),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Intervalo: ${_delayMs}ms entre envios'),
              subtitle: Slider(
                value: _delayMs.toDouble(), min: 100, max: 5000, divisions: 49,
                label: '${_delayMs}ms',
                onChanged: (v) => setState(() => _delayMs = v.round()),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Salvando…' : (isEdit ? 'Atualizar campanha' : 'Salvar campanha')),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey)),
  );

  String _fmtDt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
