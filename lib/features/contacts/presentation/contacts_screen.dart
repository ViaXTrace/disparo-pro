import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../providers/contacts_providers.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsStreamProvider);
    final groups = ref.watch(contactGroupsStreamProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contatos'),
          bottom: const TabBar(tabs: [Tab(text: 'Todos'), Tab(text: 'Grupos')]),
          actions: [
            IconButton(icon: const Icon(Icons.upload_file), tooltip: 'Importar CSV', onPressed: () => context.go('/contacts/import')),
          ],
        ),
        body: TabBarView(children: [
          Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SearchBar(
                hintText: 'Buscar por nome ou telefone…',
                leading: const Icon(Icons.search),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
                onChanged: (v) => ref.read(contactSearchProvider.notifier).state = v,
              ),
            ),
            Expanded(
              child: contacts.when(
                data: (list) => list.isEmpty
                    ? const _Empty(icon: Icons.people_outline, message: 'Nenhum contato encontrado')
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) => _ContactTile(contact: list[i], ref: ref),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
              ),
            ),
          ]),
          groups.when(
            data: (list) => list.isEmpty
                ? _Empty(
                    icon: Icons.group_outlined,
                    message: 'Nenhum grupo criado',
                    action: FilledButton.icon(
                      onPressed: () => _showCreateGroupDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Criar grupo'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _GroupTile(group: list[i], ref: ref),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
          ),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/contacts/import'),
          icon: const Icon(Icons.upload_file),
          label: const Text('Importar CSV'),
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo Grupo'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome do grupo'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Criar')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.isNotEmpty) {
      await ref.read(contactRepositoryProvider).createGroup(name: nameCtrl.text.trim());
    }
    nameCtrl.dispose();
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final WidgetRef ref;
  const _ContactTile({required this.contact, required this.ref});

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(contact.id),
    direction: DismissDirection.endToStart,
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (_) => _confirmDelete(context),
    onDismissed: (_) => ref.read(contactRepositoryProvider).delete(contact.id),
    child: ListTile(
      leading: CircleAvatar(child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?')),
      title: Text(contact.name),
      subtitle: Text(contact.phone),
      trailing: contact.optedOut
          ? const Chip(label: Text('Opt-out', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact)
          : null,
    ),
  );

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Remover contato?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
      ],
    ),
  );
}

class _GroupTile extends StatelessWidget {
  final ContactGroup group;
  final WidgetRef ref;
  const _GroupTile({required this.group, required this.ref});

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(groupContactCountProvider(group.id));
    return Card(
      child: ListTile(
        leading: const Icon(Icons.group),
        title: Text(group.name),
        subtitle: countAsync.when(
          data: (n) => Text('$n contatos'),
          loading: () => const Text('…'),
          error: (_, __) => const Text('–'),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => ref.read(contactRepositoryProvider).deleteGroup(group.id),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  const _Empty({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: Colors.grey),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(color: Colors.grey)),
      if (action != null) ...[const SizedBox(height: 16), action!],
    ]),
  );
}
