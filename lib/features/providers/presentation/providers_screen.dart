import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/gateway/gateway_registry.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/providers_providers.dart';

class ProvidersScreen extends ConsumerWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final configured = ref.watch(providersStreamProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'Provedores',
                      style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                        letterSpacing: -0.6, height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    configured.when(
                      data: (list) {
                        final active = list.where((p) => p.isActive).length;
                        return RichText(text: TextSpan(children: [
                          TextSpan(
                            text: '$active',
                            style: GoogleFonts.dmMono(
                              fontSize: 13, fontWeight: FontWeight.w700, color: accent,
                            ),
                          ),
                          TextSpan(
                            text: active == 1 ? ' ativo' : ' ativos',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ]));
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ]),
                ),
                GestureDetector(
                  onTap: () => context.go('/providers/new'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withOpacity(0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, size: 15, color: accent),
                      const SizedBox(width: 5),
                      Text('Novo', style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700, color: accent,
                      )),
                    ]),
                  ),
                ),
              ]),
            ),
          ),

          // ── Configured providers ─────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel('CONFIGURADOS', isDark: isDark),
          ),

          configured.when(
            data: (list) => list.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            Icons.info_outline_rounded, size: 16,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Nenhum provedor configurado',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  )
                : SliverList.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ConfiguredTile(
                      provider: list[i],
                      isDark: isDark,
                      accent: accent,
                      onTap: () => context.go('/providers/${list[i].id}/edit'),
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erro: $e'),
              ),
            ),
          ),

          // ── Available providers ──────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel('DISPONÍVEIS', isDark: isDark, topPadding: 28),
          ),

          SliverList.builder(
            itemCount: GatewayRegistry.allProviders.length,
            itemBuilder: (_, i) => _AvailableTile(
              meta: GatewayRegistry.allProviders[i],
              isDark: isDark,
              accent: accent,
              onTap: () => context.go('/providers/new'),
            ),
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
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final double topPadding;
  const _SectionLabel(this.text, {required this.isDark, this.topPadding = 24});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.9,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }
}

// ─── Configured provider tile ─────────────────────────────────────────────────

class _ConfiguredTile extends StatelessWidget {
  final ProviderConfig provider;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;
  const _ConfiguredTile({
    required this.provider,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final green  = isDark ? AppColors.greenDark : AppColors.greenLight;
    final muted  = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withOpacity(0.18)),
          ),
          child: Icon(Icons.dns_outlined, size: 17, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              provider.name,
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 3),
            Row(children: [
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  color: provider.isActive ? green : muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                provider.isActive
                    ? (provider.isDefault ? 'Ativo · Padrão' : 'Ativo')
                    : 'Inativo',
                style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: provider.isActive ? green : muted,
                ),
              ),
            ]),
          ]),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: border),
            ),
            child: Text('Editar', style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            )),
          ),
        ),
      ]),
    );
  }
}

// ─── Available provider tile ──────────────────────────────────────────────────

class _AvailableTile extends StatelessWidget {
  final ProviderMeta meta;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;
  const _AvailableTile({
    required this.meta,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Icon(
            Icons.cell_tower_rounded, size: 17,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              meta.label,
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              meta.channels.map((c) => c.name.toUpperCase()).join(' · '),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ]),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: accent.withOpacity(0.22)),
            ),
            child: Text('Configurar', style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600, color: accent,
            )),
          ),
        ),
      ]),
    );
  }
}
