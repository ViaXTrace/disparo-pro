import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../campaigns/providers/campaigns_providers.dart';

class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Campanhas'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Todas'), Tab(text: 'Rodando'),
            Tab(text: 'Agendadas'), Tab(text: 'Concluídas'),
          ]),
        ),
        body: const TabBarView(children: [
          _CampaignList(filter: null),
          _CampaignList(filter: 'running'),
          _CampaignList(filter: 'scheduled'),
          _CampaignList(filter: 'completed'),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/campaigns/new'),
          icon: const Icon(Icons.add),
          label: const Text('Nova Campanha'),
        ),
      ),
    );
  }
}

class _CampaignList extends ConsumerWidget {
  final String? filter;
  const _CampaignList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignsStreamProvider(filter));
    return campaigns.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.send_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(filter == null ? 'Nenhuma campanha criada' : 'Nenhuma campanha neste status',
                style: const TextStyle(color: Colors.grey)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) => _CampaignCard(campaign: list[i], ref: ref),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final WidgetRef ref;
  const _CampaignCard({required this.campaign, required this.ref});

  Color _color(String s) => switch (s) {
    'running' => Colors.blue,
    'completed' => Colors.green,
    'failed' => Colors.red,
    'scheduled' => Colors.orange,
    'paused' => Colors.amber,
    _ => Colors.grey,
  };

  String _label(String s) => switch (s) {
    'running' => 'Em andamento',
    'completed' => 'Concluída',
    'failed' => 'Falhou',
    'scheduled' => 'Agendada',
    'paused' => 'Pausada',
    _ => 'Rascunho',
  };

  IconData _channelIcon(String c) => switch (c) {
    'rcs' => Icons.chat_bubble_outline,
    'whatsapp' => Icons.chat,
    _ => Icons.sms,
  };

  @override
  Widget build(BuildContext context) {
    final prog = campaign.totalContacts > 0
        ? (campaign.sent / campaign.totalContacts).clamp(0.0, 1.0)
        : 0.0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/campaigns/${campaign.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(_channelIcon(campaign.channel), size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(campaign.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              Chip(
                label: Text(_label(campaign.status), style: const TextStyle(fontSize: 11)),
                side: BorderSide(color: _color(campaign.status)),
                padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
              ),
            ]),
            if (campaign.totalContacts > 0) ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${campaign.sent}/${campaign.totalContacts} enviadas',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${(prog * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, color: _color(campaign.status), fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: prog, color: _color(campaign.status), minHeight: 4),
            ],
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(campaign.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ]),
        ),
      ),
    );
  }
}
