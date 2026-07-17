import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contatos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar CSV',
            onPressed: () => context.go('/contacts/import'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Buscar contatos...',
              leading: const Icon(Icons.search),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 0,
              itemBuilder: (_, __) => const SizedBox.shrink(),
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhum contato cadastrado', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Importe um CSV ou adicione manualmente', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/contacts/import'),
        icon: const Icon(Icons.upload_file),
        label: const Text('Importar CSV'),
      ),
    );
  }
}
