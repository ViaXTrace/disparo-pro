import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final red    = isDark ? AppColors.redDark : AppColors.redLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 20, 24, 0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Configurações',
                  style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    letterSpacing: -0.6, height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Provedores, dados e sobre o app',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ]),
            ),
          ),

          // ── Mensagens ────────────────────────────────────────────
          _SectionSliver('MENSAGENS', isDark: isDark),
          _TileSliver(
            icon: Icons.cell_tower_rounded,
            label: 'Provedores de envio',
            subtitle: 'Zenvia, Infobip, Twilio e outros',
            border: border,
            isDark: isDark,
            onTap: () => context.go('/providers'),
          ),

          // ── Dados ────────────────────────────────────────────────
          _SectionSliver('DADOS', isDark: isDark),
          _TileSliver(
            icon: Icons.upload_file_rounded,
            label: 'Importar contatos',
            subtitle: 'Via arquivo CSV ou VCF',
            border: border,
            isDark: isDark,
            onTap: () => context.go('/contacts/import'),
          ),
          _TileSliver(
            icon: Icons.download_outlined,
            label: 'Exportar dados',
            subtitle: 'Contatos e relatórios',
            border: border,
            isDark: isDark,
            onTap: () {},
          ),
          _TileSliver(
            icon: Icons.delete_outline_rounded,
            label: 'Limpar todos os dados',
            subtitle: 'Remove contatos, campanhas e logs',
            labelColor: red,
            iconColor: red,
            border: border,
            isDark: isDark,
            onTap: () => _confirmClear(context),
          ),

          // ── Sobre ────────────────────────────────────────────────
          _SectionSliver('SOBRE', isDark: isDark),
          SliverToBoxAdapter(
            child: _VersionTile(border: border, isDark: isDark),
          ),
          _TileSliver(
            icon: Icons.code_outlined,
            label: 'Repositório GitHub',
            subtitle: 'Código aberto, sem assinatura',
            border: border,
            isDark: isDark,
            onTap: () {},
          ),

          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Limpar todos os dados?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Esta ação é irreversível. Todos os contatos, campanhas, templates e logs serão apagados.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
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

// ─── Section label sliver ─────────────────────────────────────────────────────

class _SectionSliver extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionSliver(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.9,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ),
    );
  }
}

// ─── Settings tile sliver ─────────────────────────────────────────────────────

class _TileSliver extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final Color? iconColor;
  final Color border;
  final bool isDark;
  final VoidCallback? onTap;
  const _TileSliver({
    required this.icon,
    required this.label,
    this.subtitle,
    this.labelColor,
    this.iconColor,
    required this.border,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor  = labelColor ?? (isDark ? AppColors.textDark : AppColors.textLight);
    final iColor     = iconColor  ?? (isDark ? AppColors.textSubDark : AppColors.textSubLight);

    return SliverToBoxAdapter(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iColor.withOpacity(0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: iColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: textColor,
                )),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  )),
                ],
              ]),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded, size: 18,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
          ]),
        ),
      ),
    );
  }
}

// ─── Version tile ─────────────────────────────────────────────────────────────

class _VersionTile extends StatelessWidget {
  final Color border;
  final bool isDark;
  const _VersionTile({required this.border, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.textSubDark : AppColors.textSubLight).withOpacity(0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.info_outline_rounded, size: 17,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text('Versão', style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          )),
        ),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (_, snap) => Text(
            snap.data?.version ?? '—',
            style: GoogleFonts.dmMono(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ),
      ]),
    );
  }
}
