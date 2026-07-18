import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../campaigns/providers/campaigns_providers.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final int id;
  const CampaignDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignDetailProvider(id));
    final statsAsync = ref.watch(campaignStatsProvider(id));
    final logsAsync = ref.watch(campaignLogsProvider(id));
    final repo = ref.read(campaignRepositoryProvider);

    return campaignAsync.when(
      data: (campaign) {
        if (campaign == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Campanha não encontrada')));
        }
        final prog = campaign.totalContacts > 0
            ? (campaign.sent / campaign.totalContacts).clamp(0.0, 1.0)
            : 0.0;
        final statusColor = _statusColor(campaign.status);

        return Scaffold(
          appBar: AppBar(
            title: Text(campaign.name, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.go('/campaigns/${campaign.id}/edit')),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context, ref, campaign.id),
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
            children: [
              // Status chip
              Center(
                child: Chip(
                  label: Text(_statusLabel(campaign.status), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                  side: BorderSide(color: statusColor),
                  backgroundColor: statusColor.withOpacity(0.08),
                ),
              ),
              const SizedBox(height: 12),

              // Progress card
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Progresso', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${campaign.sent} / ${campaign.totalContacts}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: prog, minHeight: 8, color: statusColor),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${(prog * 100).toStringAsFixed(1)}% concluído', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (campaign.failed > 0)
                      Text('${campaign.failed} falhas', style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ]),
                ]),
              )),
              const SizedBox(height: 12),

              // Stats row
              statsAsync.when(
                data: (s) => Row(children: [
                  Expanded(child: _MiniStat(label: 'Enviadas', value: '${s['sent'] ?? 0}', color: Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniStat(label: 'Entregues', value: '${s['delivered'] ?? 0}', color: Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniStat(label: 'Lidas', value: '${s['read'] ?? 0}', color: Colors.purple)),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniStat(label: 'Falhas', value: '${s['failed'] ?? 0}', color: Colors.red)),
                ]),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),

              // Campaign info
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Detalhes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Canal', value: campaign.channel.toUpperCase()),
                  _InfoRow(label: 'Criada em', value: DateFormat('dd/MM/yyyy HH:mm').format(campaign.createdAt)),
                  if (campaign.scheduledAt != null)
                    _InfoRow(label: 'Agendada para', value: DateFormat('dd/MM/yyyy HH:mm').format(campaign.scheduledAt!)),
                  if (campaign.startedAt != null)
                    _InfoRow(label: 'Iniciada em', value: DateFormat('dd/MM/yyyy HH:mm').format(campaign.startedAt!)),
                  if (campaign.completedAt != null)
                    _InfoRow(label: 'Concluída em', value: DateFormat('dd/MM/yyyy HH:mm').format(campaign.completedAt!)),
                ]),
              )),
              const SizedBox(height: 12),

              // Message body
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mensagem', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(campaign.messageBody),
                  ),
                ]),
              )),
              const SizedBox(height: 12),

              // Recent logs
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Últimos registros', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  logsAsync.when(
                    data: (logs) {
                      if (logs.isEmpty) return const Text('Nenhum registro ainda', style: TextStyle(color: Colors.grey));
                      return Column(children: logs.take(20).map((log) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Icon(_logIcon(log.status), size: 16, color: _logColor(log.status)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(log.phone, style: const TextStyle(fontSize: 13))),
                          Text(log.status, style: TextStyle(fontSize: 11, color: _logColor(log.status))),
                        ]),
                      )).toList());
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ]),
              )),

            ],
          ),
          bottomNavigationBar: _BottomActions(campaign: campaign, repo: repo),
        );
      },
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Erro: $e'))),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir campanha?'),
        content: const Text('Todos os registros de envio também serão removidos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(campaignRepositoryProvider).delete(id);
      if (context.mounted) context.go('/campaigns');
    }
  }

  Color _statusColor(String s) => switch (s) {
    'running' => Colors.blue,
    'completed' => Colors.green,
    'failed' => Colors.red,
    'scheduled' => Colors.orange,
    'paused' => Colors.amber,
    _ => Colors.grey,
  };

  String _statusLabel(String s) => switch (s) {
    'running' => 'Em andamento',
    'completed' => 'Concluída',
    'failed' => 'Falhou',
    'scheduled' => 'Agendada',
    'paused' => 'Pausada',
    _ => 'Rascunho',
  };

  IconData _logIcon(String s) => switch (s) {
    'delivered' || 'read' => Icons.check_circle,
    'failed' => Icons.cancel,
    'sent' => Icons.check,
    _ => Icons.schedule,
  };

  Color _logColor(String s) => switch (s) {
    'delivered' || 'read' => Colors.green,
    'failed' => Colors.red,
    'sent' => Colors.blue,
    _ => Colors.grey,
  };
}

class _BottomActions extends StatelessWidget {
  final dynamic campaign;
  final dynamic repo;
  const _BottomActions({required this.campaign, required this.repo});

  @override
  Widget build(BuildContext context) {
    final status = campaign.status as String;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      child: Row(children: [
        if (status == 'running') ...[
          Expanded(child: FilledButton.tonal(onPressed: () => repo.pause(campaign.id), child: const Text('Pausar'))),
          const SizedBox(width: 12),
        ],
        if (status == 'paused') ...[
          Expanded(child: FilledButton.tonal(onPressed: () => repo.resume(campaign.id), child: const Text('Retomar'))),
          const SizedBox(width: 12),
        ],
        if (status == 'draft' || status == 'paused' || status == 'failed')
          Expanded(child: FilledButton.icon(
            onPressed: () => repo.dispatch(campaign.id),
            icon: const Icon(Icons.send),
            label: const Text('Disparar agora'),
          )),
        if (status == 'scheduled')
          Expanded(child: FilledButton.tonal(
            onPressed: () => repo.dispatch(campaign.id),
            child: const Text('Disparar agora'),
          )),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
    ])),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    ]),
  );
}
