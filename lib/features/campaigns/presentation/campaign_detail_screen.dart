import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String id;
  const CampaignDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: watch campaignDetailProvider(int.parse(id))
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Campanha'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progresso', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(value: 0),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0 enviados'),
                      Text('0 de 0'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _StatRow(),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mensagem', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('—'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
        child: Row(
          children: [
            Expanded(child: FilledButton.tonal(onPressed: () {}, child: const Text('Pausar'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () {}, child: const Text('Disparar'))),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _MiniStat(label: 'Entregues', value: '—', color: Colors.green)),
      const SizedBox(width: 8),
      Expanded(child: _MiniStat(label: 'Falhas', value: '—', color: Colors.red)),
      const SizedBox(width: 8),
      Expanded(child: _MiniStat(label: 'Lidas', value: '—', color: Colors.blue)),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
