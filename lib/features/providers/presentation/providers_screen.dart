import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/gateway/gateway_registry.dart';

class ProvidersScreen extends ConsumerWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provedores')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
        children: [
          Text('Provedores configurados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // TODO: watch configured providers from DB
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum provedor configurado', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Provedores disponíveis', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...GatewayRegistry.allProviders.map((meta) => Card(
            child: ListTile(
              title: Text(meta.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(meta.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...meta.channels.map((ch) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Chip(
                      label: Text(ch.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () => context.go('/providers/new'),
                    child: const Text('Configurar'),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          )),
        ],
      ),
    );
  }
}
