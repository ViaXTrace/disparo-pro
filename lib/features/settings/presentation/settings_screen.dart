import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          _Section(title: 'Provedores de mensagens'),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Gerenciar provedores'),
            subtitle: const Text('Configure Zenvia, Infobip, Twilio e outros'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/providers'),
          ),
          _Section(title: 'Dados'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Importar contatos'),
            subtitle: const Text('Importar lista via arquivo CSV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/contacts/import'),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Exportar dados'),
            subtitle: const Text('Exportar contatos e relatórios'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Limpar todos os dados', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Remove contatos, campanhas e logs'),
            onTap: () => _confirmClear(context),
          ),
          _Section(title: 'Sobre'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versão'),
            trailing: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) => Text(snap.data?.version ?? '—'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('Repositório GitHub'),
            subtitle: const Text('Código aberto, sem assinatura'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpar todos os dados?'),
        content: const Text('Esta ação é irreversível. Todos os contatos, campanhas, templates e logs serão apagados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar tudo'),
          ),
        ],
      ),
    );
    if (ok == true) {
      // TODO: clear all tables via repository
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      )),
    );
  }
}
