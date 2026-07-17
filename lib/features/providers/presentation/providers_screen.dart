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
          Text(
            'Provedores configurados',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // TODO: watch configured providers from DB
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Nenhum provedor configurado',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Provedores disponíveis',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...GatewayRegistry.allProviders.map(
            (meta) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row: name + button ──────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            meta.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => context.go('/providers/new'),
                          child: const Text('Configurar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // ── Description ───────────────────────────────
                    Text(
                      meta.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 10),
                    // ── Channel chips ─────────────────────────────
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: meta.channels.map((ch) {
                        return Chip(
                          label: Text(
                            ch.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
