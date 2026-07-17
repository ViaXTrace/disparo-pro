import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disparo Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_outlined),
            tooltip: 'Provedores',
            onPressed: () => context.go('/providers'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatsRow(),
          const SizedBox(height: 20),
          _QuickActions(),
          const SizedBox(height: 20),
          _RecentCampaigns(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/campaigns/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova Campanha'),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Enviadas hoje', value: '—', icon: Icons.send, color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Entregues', value: '—', icon: Icons.check_circle, color: Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Falhas', value: '—', icon: Icons.error_outline, color: Colors.red)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ações rápidas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionChip(label: 'Importar contatos', icon: Icons.upload_file, onTap: () => context.go('/contacts/import')),
            const SizedBox(width: 8),
            _ActionChip(label: 'Novo template', icon: Icons.add_box_outlined, onTap: () => context.go('/templates/new')),
            const SizedBox(width: 8),
            _ActionChip(label: 'Relatórios', icon: Icons.bar_chart, onTap: () => context.go('/reports')),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
    );
  }
}

class _RecentCampaigns extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Campanhas recentes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => context.go('/campaigns'), child: const Text('Ver todas')),
          ],
        ),
        const SizedBox(height: 8),
        const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nenhuma campanha ainda.\nCrie sua primeira campanha!', textAlign: TextAlign.center))),
      ],
    );
  }
}
