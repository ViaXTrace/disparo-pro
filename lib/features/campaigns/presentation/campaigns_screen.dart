import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            Tab(text: 'Todas'),
            Tab(text: 'Em andamento'),
            Tab(text: 'Agendadas'),
            Tab(text: 'Concluídas'),
          ]),
        ),
        body: const TabBarView(children: [
          _CampaignList(filter: 'all'),
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
  final String filter;
  const _CampaignList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: watch campaignListProvider(filter)
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.send_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Nenhuma campanha aqui', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
