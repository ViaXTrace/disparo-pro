import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CampaignFormScreen extends ConsumerStatefulWidget {
  final String? id;
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
      appBar: AppBar(title: Text(isEdit ? 'Editar Campanha' : 'Nova Campanha')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Identificação'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome da campanha'),
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            _section('Canal de envio'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sms', label: Text('SMS'), icon: Icon(Icons.sms)),
                ButtonSegment(value: 'rcs', label: Text('RCS'), icon: Icon(Icons.chat_bubble_outline)),
                ButtonSegment(value: 'whatsapp', label: Text('WhatsApp'), icon: Icon(Icons.whatsapp)),
              ],
              selected: {_channel},
              onSelectionChanged: (v) => setState(() => _channel = v.first),
            ),
            const SizedBox(height: 16),
            _section('Provedor'),
            DropdownButtonFormField<int>(
              value: _providerId,
              hint: const Text('Selecione um provedor'),
              decoration: const InputDecoration(labelText: 'Provedor'),
              items: const [], // TODO: load from providers
              onChanged: (v) => setState(() => _providerId = v),
              validator: (v) => v == null ? 'Selecione um provedor' : null,
            ),
            const SizedBox(height: 16),
            _section('Destinatários'),
            DropdownButtonFormField<int>(
              value: _groupId,
              hint: const Text('Selecione um grupo de contatos'),
              decoration: const InputDecoration(labelText: 'Grupo de Contatos'),
              items: const [], // TODO: load from contact_groups
              onChanged: (v) => setState(() => _groupId = v),
            ),
            const SizedBox(height: 16),
            _section('Mensagem'),
            DropdownButtonFormField<int>(
              value: _templateId,
              hint: const Text('Usar template (opcional)'),
              decoration: const InputDecoration(labelText: 'Template'),
              items: const [], // TODO: load from templates
              onChanged: (v) {
                setState(() => _templateId = v);
                // TODO: fill _bodyCtrl with template content
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Corpo da mensagem',
                hintText: 'Use {{nome}}, {{variavel}} para personalizar',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            _section('Agendamento'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disparar em'),
              subtitle: Text(_scheduledAt == null
                  ? 'Imediatamente após salvar'
                  : '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} ${_scheduledAt!.hour}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scheduledAt != null)
                    IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _scheduledAt = null)),
                  FilledButton.tonal(onPressed: _pickSchedule, child: const Text('Agendar')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _section('Controle de velocidade'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Lote: $_batchSize mensagens'),
              subtitle: Slider(value: _batchSize.toDouble(), min: 10, max: 500, divisions: 49, onChanged: (v) => setState(() => _batchSize = v.round())),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Intervalo: ${_delayMs}ms entre envios'),
              subtitle: Slider(value: _delayMs.toDouble(), min: 100, max: 5000, divisions: 49, onChanged: (v) => setState(() => _delayMs = v.round())),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(_saving ? 'Salvando...' : 'Salvar campanha'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey)),
      );

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(hours: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 300)); // TODO: insert via repository
    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/campaigns');
  }
}
