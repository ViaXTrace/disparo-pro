import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = Theme.of(context).colorScheme.primary;
    final border  = isDark ? AppColors.borderDark : AppColors.borderLight;
    final green   = isDark ? AppColors.greenDark  : AppColors.greenLight;
    final red     = isDark ? AppColors.redDark    : AppColors.redLight;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 20, 24, 0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'Relatórios',
                      style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                        letterSpacing: -0.6, height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Taxas de entrega por canal',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ]),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Icon(
                      Icons.download_outlined, size: 18,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                    ),
                  ),
                ),
              ]),
            ),
          ),

          // ── Period selector ──────────────────────────────────────
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
            sliver: SliverToBoxAdapter(child: _PeriodSelector()),
          ),

          // ── Summary cards ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Expanded(child: _StatCard(
                  label: 'Enviadas', value: '0',
                  icon: Icons.send_rounded, color: accent, isDark: isDark,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(
                  label: 'Entregues', value: '0%',
                  icon: Icons.check_circle_outline_rounded, color: green, isDark: isDark,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(
                  label: 'Falhas', value: '0%',
                  icon: Icons.cancel_outlined, color: red, isDark: isDark,
                )),
              ]),
            ),
          ),

          // ── Deliveries chart placeholder ─────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Envios por dia', style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  )),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          Icons.bar_chart_rounded, size: 40,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dados disponíveis após primeiros disparos',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // ── Channel delivery rates ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Taxa por canal', style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  )),
                  const SizedBox(height: 14),
                  _ChannelBar(label: 'SMS',      color: accent,                            sent: 0, delivered: 0, isDark: isDark),
                  const SizedBox(height: 12),
                  _ChannelBar(label: 'RCS',      color: const Color(0xFFA78BFA),           sent: 0, delivered: 0, isDark: isDark),
                  const SizedBox(height: 12),
                  _ChannelBar(label: 'WhatsApp', color: green,                             sent: 0, delivered: 0, isDark: isDark),
                ]),
              ),
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

// ─── Period selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends StatefulWidget {
  const _PeriodSelector();
  @override
  State<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelector> {
  String _period = '7d';

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      style: SegmentedButton.styleFrom(textStyle: const TextStyle(fontSize: 12)),
      segments: const [
        ButtonSegment(value: '7d',  label: Text('7 dias')),
        ButtonSegment(value: '30d', label: Text('30 dias')),
        ButtonSegment(value: '90d', label: Text('90 dias')),
        ButtonSegment(value: 'all', label: Text('Tudo')),
      ],
      selected: {_period},
      onSelectionChanged: (v) => setState(() => _period = v.first),
    );
  }
}

// ─── Summary stat card ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.dmMono(
          fontSize: 17, fontWeight: FontWeight.w800,
          color: isDark ? AppColors.textDark : AppColors.textLight,
          letterSpacing: -0.5,
        )),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(
          fontSize: 10,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── Channel progress bar ─────────────────────────────────────────────────────

class _ChannelBar extends StatelessWidget {
  final String label;
  final Color color;
  final int sent, delivered;
  final bool isDark;
  const _ChannelBar({
    required this.label, required this.color,
    required this.sent, required this.delivered, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rate = sent == 0 ? 0.0 : (delivered / sent).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        )),
        Text(
          '${(rate * 100).toStringAsFixed(1)}%',
          style: GoogleFonts.dmMono(
            fontSize: 12, fontWeight: FontWeight.w700, color: color,
          ),
        ),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: rate, minHeight: 5,
          color: color,
          backgroundColor: color.withOpacity(isDark ? 0.12 : 0.10),
        ),
      ),
    ]);
  }
}
