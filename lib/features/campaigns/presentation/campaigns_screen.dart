import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/campaigns_providers.dart';

class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});

  @override
  ConsumerState<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends ConsumerState<CampaignsScreen> {
  int _tab = 0;
  static const _tabs = ['Todas', 'Rodando', 'Agendadas', 'Concluídas'];
  static const _filters = [null, 'running', 'scheduled', 'completed'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final campaigns = ref.watch(campaignsStreamProvider(_filters[_tab]));
    final countAll  = ref.watch(campaignsStreamProvider(null));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverPadding(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'Campanhas',
                      style: GoogleFonts.dmSans(
                        fontSize: 26, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                        letterSpacing: -0.6, height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    countAll.when(
                      data: (list) => RichText(text: TextSpan(children: [
                        TextSpan(
                          text: '${list.length}',
                          style: GoogleFonts.dmMono(
                            fontSize: 13, fontWeight: FontWeight.w700, color: accent,
                          ),
                        ),
                        TextSpan(
                          text: ' no total',
                          style: GoogleFonts.dmSans(
                            fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ])),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ]),
                ),
                // Nova campanha
                GestureDetector(
                  onTap: () => context.go('/campaigns/new'),
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
                      Text('Nova', style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: accent,
                      )),
                    ]),
                  ),
                ),
              ]),
            ),
          ),

          // Segmented filter
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final active = _tab == i;
                    return Padding(
                      padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: active ? accent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                          ),
                          child: Text(
                            _tabs[i],
                            style: GoogleFonts.dmSans(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: active ? Colors.white : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // Campaign list
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          campaigns.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    message: _tab == 0 ? 'Nenhuma campanha criada' : 'Nenhuma campanha neste status',
                    onNew: _tab == 0 ? () => context.go('/campaigns/new') : null,
                  ),
                );
              }
              return SliverList.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => _CampaignCard(campaign: list[i], ref: ref),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Erro: $e')),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ─── Campaign card ────────────────────────────────────────────────────────────

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final WidgetRef ref;
  const _CampaignCard({required this.campaign, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = _status(context, campaign.status);
    final pct = campaign.totalContacts > 0
        ? (campaign.sent / campaign.totalContacts).clamp(0.0, 1.0)
        : 0.0;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return InkWell(
      onTap: () => context.go('/campaigns/${campaign.id}'),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: border)),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Accent strip
            Container(width: 3, color: s.color),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 18, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Title row
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          campaign.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14.5, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                            letterSpacing: -0.2, height: 1.25,
                          ),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(children: [
                          _ChannelBadge(channel: campaign.channel, isDark: isDark),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM').format(campaign.createdAt),
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    // Status indicator
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 5, height: 5,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        s.label.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: s.color, letterSpacing: 0.4,
                        ),
                      ),
                    ]),
                  ]),

                  // Progress
                  if (campaign.totalContacts > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 2,
                        color: s.color,
                        backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.07),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(
                        '${_fmtNum(campaign.sent)} / ${_fmtNum(campaign.totalContacts)}',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.dmMono(
                          fontSize: 11, fontWeight: FontWeight.w700, color: s.color,
                        ),
                      ),
                    ]),
                  ],

                  // Actions for running campaigns
                  if (campaign.status == 'running') ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {/* pause */},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            foregroundColor: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                            textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Pausar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/campaigns/${campaign.id}'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Detalhes'),
                        ),
                      ),
                    ]),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  ({String label, Color color}) _status(BuildContext context, String s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (s) {
      'running'   => (label: 'Rodando',   color: Theme.of(context).colorScheme.primary),
      'completed' => (label: 'Concluída', color: isDark ? AppColors.greenDark : AppColors.greenLight),
      'failed'    => (label: 'Falhou',    color: isDark ? AppColors.redDark : AppColors.redLight),
      'scheduled' => (label: 'Agendada',  color: isDark ? AppColors.amberDark : AppColors.amberLight),
      'paused'    => (label: 'Pausada',   color: isDark ? AppColors.textSubDark : AppColors.textSubLight),
      _           => (label: 'Rascunho',  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
    };
  }

  String _fmtNum(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toString();
  }
}

// ─── Channel badge ────────────────────────────────────────────────────────────

class _ChannelBadge extends StatelessWidget {
  final String channel;
  final bool isDark;
  const _ChannelBadge({required this.channel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final label = switch (channel) {
      'whatsapp' => 'WA',
      'rcs'      => 'RCS',
      _          => 'SMS',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmMono(
          fontSize: 9.5, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onNew;
  const _EmptyState({required this.message, this.onNew});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(
        Icons.send_outlined,
        size: 48,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
      const SizedBox(height: 12),
      Text(message, style: GoogleFonts.dmSans(
        fontSize: 14,
        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
      )),
      if (onNew != null) ...[
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onNew,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Criar campanha'),
        ),
      ],
    ]);
  }
}
