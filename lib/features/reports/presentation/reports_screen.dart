import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../campaigns/providers/campaigns_providers.dart';

// ── Period filter provider ─────────────────────────────────────────────────────
final reportsPeriodProvider = StateProvider<String>((ref) => '30d');

// ── Derived stats provider ────────────────────────────────────────────────────
final reportsStatsProvider = FutureProvider<_ReportStats>((ref) async {
  final period = ref.watch(reportsPeriodProvider);
  final repo   = ref.watch(campaignRepositoryProvider);
  return _ReportStats.fromLogs(await repo.getAllLogs(), period);
});

// ─────────────────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = Theme.of(context).colorScheme.primary;
    final border  = isDark ? AppColors.borderDark : AppColors.borderLight;
    final green   = isDark ? AppColors.greenDark  : AppColors.greenLight;
    final red     = isDark ? AppColors.redDark    : AppColors.redLight;
    final period  = ref.watch(reportsPeriodProvider);
    final stats   = ref.watch(reportsStatsProvider);

    return Scaffold(
      body: RefreshIndicator(
        displacement: 80,
        onRefresh: () async => ref.invalidate(reportsStatsProvider),
        child: CustomScrollView(
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
                ]),
              ),
            ),

            // ── Period selector ──────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(textStyle: GoogleFonts.poppins(fontSize: 12)),
                  segments: const [
                    ButtonSegment(value: '7d',  label: Text('7 dias')),
                    ButtonSegment(value: '30d', label: Text('30 dias')),
                    ButtonSegment(value: '90d', label: Text('90 dias')),
                    ButtonSegment(value: 'all', label: Text('Tudo')),
                  ],
                  selected: {period},
                  onSelectionChanged: (v) =>
                      ref.read(reportsPeriodProvider.notifier).state = v.first,
                ),
              ),
            ),

            // ── Summary cards ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverToBoxAdapter(
                child: stats.when(
                  data: (s) {
                    final deliveryRate = s.sent == 0
                        ? '—'
                        : '${((s.delivered / s.sent) * 100).toStringAsFixed(1)}%';
                    final failRate = s.sent == 0
                        ? '—'
                        : '${((s.failed / s.sent) * 100).toStringAsFixed(1)}%';
                    return Row(children: [
                      Expanded(child: _StatCard(
                        label: 'Enviadas', value: '${s.sent}',
                        icon: Icons.send_rounded, color: accent, isDark: isDark,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(
                        label: 'Entregues', value: deliveryRate,
                        icon: Icons.check_circle_outline_rounded, color: green, isDark: isDark,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(
                        label: 'Falhas', value: failRate,
                        icon: Icons.cancel_outlined, color: red, isDark: isDark,
                      )),
                    ]);
                  },
                  loading: () => Row(children: [
                    Expanded(child: _StatCard(label: 'Enviadas', value: '…', icon: Icons.send_rounded, color: accent, isDark: isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(label: 'Entregues', value: '…', icon: Icons.check_circle_outline_rounded, color: green, isDark: isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(label: 'Falhas', value: '…', icon: Icons.cancel_outlined, color: red, isDark: isDark)),
                  ]),
                  error: (e, _) => Center(child: Text('Erro: $e')),
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
                    stats.when(
                      data: (s) => Column(children: [
                        _ChannelBar(
                          label: 'SMS',
                          color: accent,
                          sent: s.byCh['sms']?['sent'] ?? 0,
                          delivered: s.byCh['sms']?['delivered'] ?? 0,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _ChannelBar(
                          label: 'RCS',
                          color: const Color(0xFFA78BFA),
                          sent: s.byCh['rcs']?['sent'] ?? 0,
                          delivered: s.byCh['rcs']?['delivered'] ?? 0,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _ChannelBar(
                          label: 'WhatsApp',
                          color: green,
                          sent: s.byCh['whatsapp']?['sent'] ?? 0,
                          delivered: s.byCh['whatsapp']?['delivered'] ?? 0,
                          isDark: isDark,
                        ),
                      ]),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                      error: (e, _) => Text('Erro: $e'),
                    ),
                  ]),
                ),
              ),
            ),

            // ── Detailed log table ────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverToBoxAdapter(
                child: stats.when(
                  data: (s) {
                    if (s.sent == 0) {
                      return Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Column(children: [
                          Icon(Icons.bar_chart_rounded, size: 40,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          const SizedBox(height: 12),
                          Text(
                            'Dados disponíveis após os primeiros disparos',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                      );
                    }
                    return _RecentLogsList(logs: s.recentLogs, isDark: isDark, border: border);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 80,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _ReportStats {
  final int sent, delivered, failed;
  final Map<String, Map<String, int>> byCh;
  final List<MessageLog> recentLogs;

  const _ReportStats({
    required this.sent,
    required this.delivered,
    required this.failed,
    required this.byCh,
    required this.recentLogs,
  });

  factory _ReportStats.fromLogs(List<MessageLog> allLogs, String period) {
    final cutoff = switch (period) {
      '7d'  => DateTime.now().subtract(const Duration(days: 7)),
      '30d' => DateTime.now().subtract(const Duration(days: 30)),
      '90d' => DateTime.now().subtract(const Duration(days: 90)),
      _     => DateTime(2000),
    };

    final logs = allLogs.where((l) => l.createdAt.isAfter(cutoff)).toList();
    logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int sent = 0, delivered = 0, failed = 0;
    final byCh = <String, Map<String, int>>{};

    for (final l in logs) {
      final ch = byCh.putIfAbsent(l.channel, () => {'sent': 0, 'delivered': 0, 'failed': 0});
      if (l.status != 'pending') {
        sent++;
        ch['sent'] = (ch['sent'] ?? 0) + 1;
      }
      if (l.status == 'delivered' || l.status == 'read') {
        delivered++;
        ch['delivered'] = (ch['delivered'] ?? 0) + 1;
      }
      if (l.status == 'failed') {
        failed++;
        ch['failed'] = (ch['failed'] ?? 0) + 1;
      }
    }

    return _ReportStats(
      sent: sent,
      delivered: delivered,
      failed: failed,
      byCh: byCh,
      recentLogs: logs.take(50).toList(),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.dmMono(
          fontSize: 20, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5,
        )),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(
          fontSize: 10.5,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        )),
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
  const _ChannelBar({required this.label, required this.color, required this.sent, required this.delivered, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rate = sent == 0 ? 0.0 : (delivered / sent).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Text(label, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          )),
          const SizedBox(width: 8),
          Text('$sent enviados', style: GoogleFonts.poppins(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          )),
        ]),
        Text(
          sent == 0 ? '—' : '${(rate * 100).toStringAsFixed(1)}%',
          style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w700, color: color),
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

// ─── Recent logs list ─────────────────────────────────────────────────────────

class _RecentLogsList extends StatelessWidget {
  final List<MessageLog> logs;
  final bool isDark;
  final Color border;
  const _RecentLogsList({required this.logs, required this.isDark, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text('Últimos envios', style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          )),
        ),
        const Divider(height: 1),
        ...logs.take(20).map((l) => _LogRow(log: l, isDark: isDark, border: border)),
      ]),
    );
  }
}

class _LogRow extends StatelessWidget {
  final MessageLog log;
  final bool isDark;
  final Color border;
  const _LogRow({required this.log, required this.isDark, required this.border});

  Color get _statusColor {
    return switch (log.status) {
      'delivered' || 'read' => isDark ? AppColors.greenDark : AppColors.greenLight,
      'failed'              => isDark ? AppColors.redDark   : AppColors.redLight,
      'sent'                => isDark ? AppColors.accentDark : AppColors.accentLight,
      _                     => isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
    };
  }

  String get _statusLabel => switch (log.status) {
    'delivered' => 'Entregue',
    'read'      => 'Lida',
    'sent'      => 'Enviado',
    'failed'    => 'Falha',
    'pending'   => 'Aguardando',
    _           => log.status,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(log.phone, style: GoogleFonts.dmMono(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            )),
            const SizedBox(height: 2),
            Text(log.channel.toUpperCase(), style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            )),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(_statusLabel, style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor,
          )),
        ),
      ]),
    );
  }
}
