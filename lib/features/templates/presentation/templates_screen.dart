import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../templates/providers/templates_providers.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesStreamProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: templates.when(
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Nenhum template criado', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go('/templates/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Criar template'),
                ),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) => _TemplateTile(template: list[i], ref: ref),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/templates/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Template'),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final dynamic template;
  final WidgetRef ref;
  const _TemplateTile({required this.template, required this.ref});

  Color _channelColor(String c) => switch (c) {
    'rcs' => Colors.purple,
    'whatsapp' => Colors.green,
    'sms' => Colors.blue,
    _ => Colors.grey,
  };

  String _channelLabel(String c) => switch (c) {
    'rcs' => 'RCS',
    'whatsapp' => 'WhatsApp',
    'sms' => 'SMS',
    _ => 'Todos',
  };

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('/templates/${template.id}/edit'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(template.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            Chip(
              label: Text(_channelLabel(template.channel), style: const TextStyle(fontSize: 10)),
              side: BorderSide(color: _channelColor(template.channel)),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _confirmDelete(context),
              color: Colors.red,
              visualDensity: VisualDensity.compact,
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            template.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ]),
      ),
    ),
  );

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir template?'),
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
      await ref.read(templateRepositoryProvider).delete(template.id);
    }
  }
}
