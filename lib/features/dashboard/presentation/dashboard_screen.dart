import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../campaigns/providers/campaigns_providers.dart';
import '../../contacts/providers/contacts_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final contacts = ref.watch(contactCountProvider);
    final recentCampaigns = ref.watch(campaignsStreamProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disparo Pro'),
        actions: [
          IconButton(icon: const Icon(Icons.dns_outlined), tooltip: 'Provedores', onPressed: () => context.go('/providers')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(contactCountProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats row
            stats.when(
              data: (s) => Row(children: [
                Expanded(child: _StatCard(label: 'Enviadas hoje', value: _fmt(s['sent_today'] ?? 0), icon: Icons.send, color: Colors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Entregues', value: _fmt(s['delivered_today'] ?? 0), icon: Icons.check_circle, color: Colors.green)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Falhas', value: _fmt(s['failed_today'] ?? 0), icon: Icons.error_outline, color: Colors.red)),
              ]),
              loading: () => const _StatsShimmer(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            // Contact count banner
            contacts.when(
              data: (count) => count == 0
                  ? _EmptyBanner(onTap: () => context.go('/contacts/import'))
                  : _ContactBanner(count: count),
              loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            // Quick actions
            Text('Ações rápidas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('Nova Campanha'), onPressed: () => context.go('/campaigns/new')),
              ActionChip(avatar: const Icon(Icons.upload_file, size: 16), label: const Text('Importar Contatos'), onPressed: () => context.go('/contacts/import')),
              ActionChip(avatar: const Icon(Icons.article_outlined, size: 16), label: const Text('Novo Template'), onPressed: () => context.go('/templates/new')),
              ActionChip(avatar: const Icon(Icons.bar_chart, size: 16), label: const Text('Relatórios'), onPressed: () => context.go('/reports')),
            ]),
            const SizedBox(height: 20),
            // Recent campaigns
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Campanhas recentes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => context.go('/campaigns'), child: const Text('Ver todas')),
              ],
            ),
            const SizedBox(height: 8),
            recentCampaigns.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Nenhuma campanha ainda.', style: TextStyle(color: Colors.grey))),
                  );
                }
                return Column(
                  children: list.take(5).map((c) => _CampaignTile(campaign: c)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro: $e'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/campaigns/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova Campanha'),
      ),
    );
  }

  String _fmt(int n) => NumberFormat.compact().format(n);
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    ),
  );
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();
  @override
  Widget build(BuildContext context) => Row(children: List.generate(3, (i) => Expanded(
    child: Padding(
      padding: EdgeInsets.only(left: i > 0 ? 10 : 0),
      child: Card(child: Container(height: 90, decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ))),
    ),
  )));
}

class _EmptyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyBanner({required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: ListTile(
      leading: const Icon(Icons.people_outline),
      title: const Text('Importe seus contatos para começar'),
      subtitle: const Text('Suporta CSV — clique para importar'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _ContactBanner extends StatelessWidget {
  final int count;
  const _ContactBanner({required this.count});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.people, color: Colors.blue),
      title: Text('${NumberFormat.compact().format(count)} contatos cadastrados'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => GoRouter.of(context).go('/contacts'),
    ),
  );
}

class _CampaignTile extends StatelessWidget {
  final dynamic campaign;
  const _CampaignTile({required this.campaign});

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

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(campaign.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(campaign.channel.toUpperCase()),
      trailing: Chip(
        label: Text(_statusLabel(campaign.status), style: const TextStyle(fontSize: 11)),
        side: BorderSide(color: _statusColor(campaign.status)),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
      onTap: () => context.go('/campaigns/${campaign.id}'),
    ),
  );
}
