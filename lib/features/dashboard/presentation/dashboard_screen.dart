import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../campaigns/providers/campaigns_providers.dart';
import '../../contacts/providers/contacts_providers.dart';
import '../../../core/database/app_database.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync      = ref.watch(dashboardStatsProvider);
    final recentCampaigns = ref.watch(campaignsStreamProvider(null));

    return Scaffold(
      body: RefreshIndicator(
        displacement: 80,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(contactCountProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────
            _DashboardAppBar(),

            // ── Delivery ring ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: statsAsync.when(
                  data: (s) {
                    final sent      = (s['sent_today']      ?? 0).toDouble();
                    final delivered = (s['delivered_today'] ?? 0).toDouble();
                    final failed    = (s['failed_today']    ?? 0).toInt();
                    final pct = sent > 0 ? (delivered / sent).clamp(0.0, 1.0) : 0.0;
                    return _DeliveryCard(
                      pct: pct,
                      sent: sent.toInt(),
                      delivered: delivered.toInt(),
                      failed: failed,
                    );
                  },
                  loading: () => _DeliveryCard(pct: 0, sent: 0, delivered: 0, failed: 0, shimmer: true),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // ── Mini stat row ─────────────────────────────────────
            SliverToBoxAdapter(
              child: statsAsync.when(
                data: (s) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(children: [
                    _MiniStat(label: 'Hoje',   value: s['sent_today'] ?? 0,  color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    _MiniStat(label: 'Semana', value: s['sent_week']  ?? 0,  color: _green(context)),
                    const SizedBox(width: 8),
                    _MiniStat(label: 'Mês',    value: s['sent_month'] ?? 0,  color: _amber(context)),
                  ]),
                ),
                loading: () => const SizedBox(height: 80),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── Quick actions ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionLabel('Ações rápidas'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _QuickAction(label: 'Nova campanha', icon: Icons.add_rounded,        primary: true,  onTap: () => context.go('/campaigns/new')),
                    _QuickAction(label: 'Importar CSV',  icon: Icons.upload_file_rounded, primary: false, onTap: () => context.go('/contacts/import')),
                    _QuickAction(label: 'Templates',     icon: Icons.article_outlined,    primary: false, onTap: () => context.go('/templates')),
                  ]),
                ]),
              ),
            ),

            // ── Recent campaigns ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionLabel('Campanhas recentes'),
                    GestureDetector(
                      onTap: () => context.go('/campaigns'),
                      child: Text(
                        'Ver tudo →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            recentCampaigns.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(child: _EmptyState(
                    icon: Icons.send_outlined,
                    message: 'Nenhuma campanha ainda',
                    action: 'Criar campanha',
                    onAction: () => context.go('/campaigns/new'),
                  ));
                }
                final recent = list.take(4).toList();
                return SliverList.builder(
                  itemCount: recent.length,
                  itemBuilder: (_, i) => _CampaignRow(campaign: recent[i], isLast: i == recent.length - 1),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ))),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ── Provider card ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ProviderCard(onTap: () => context.go('/providers')),
              ),
            ),

            SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16)),
          ],
        ),
      ),
    );
  }

  Color _green(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.greenDark : AppColors.greenLight;

  Color _amber(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.amberDark : AppColors.amberLight;
}

// ─── App bar ─────────────────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Bom dia, Rafael',
                style: GoogleFonts.poppins(
                  fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'DyanX',
                style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                  letterSpacing: -0.6, height: 1.1,
                ),
              ),
            ]),
            const Spacer(),
            // Signal icon
            GestureDetector(
              onTap: () => context.go('/providers'),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Icon(
                  Icons.cell_tower_rounded,
                  size: 20,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Delivery ring card ───────────────────────────────────────────────────────

class _DeliveryCard extends StatelessWidget {
  final double pct;
  final int sent, delivered, failed;
  final bool shimmer;
  const _DeliveryCard({
    required this.pct, required this.sent,
    required this.delivered, required this.failed,
    this.shimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.0 : 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
      child: Column(children: [
        // Ring
        _DeliveryRing(pct: shimmer ? 0 : pct, accent: accent, isDark: isDark),
        const SizedBox(height: 16),
        // Sub stats
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SubStat(label: 'Enviadas',   value: sent,      color: isDark ? AppColors.textSubDark : AppColors.textSubLight),
            _SubStatDivider(),
            _SubStat(label: 'Entregues',  value: delivered, color: isDark ? AppColors.greenDark : AppColors.greenLight),
            _SubStatDivider(),
            _SubStat(label: 'Falhas',     value: failed,    color: isDark ? AppColors.redDark : AppColors.redLight),
          ],
        ),
      ]),
    );
  }
}

class _DeliveryRing extends StatefulWidget {
  final double pct;
  final Color accent;
  final bool isDark;
  const _DeliveryRing({required this.pct, required this.accent, required this.isDark});

  @override
  State<_DeliveryRing> createState() => _DeliveryRingState();
}

class _DeliveryRingState extends State<_DeliveryRing> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    if (widget.pct > 0) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_DeliveryRing old) {
    super.didUpdateWidget(old);
    if (old.pct != widget.pct && widget.pct > 0) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final drawn = _anim.value * widget.pct;
        return SizedBox(
          width: 152, height: 152,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(152, 152),
              painter: _RingPainter(
                progress: drawn,
                accent: widget.accent,
                trackColor: widget.isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.07),
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${(drawn * 100).toStringAsFixed(1)}',
                      style: GoogleFonts.dmMono(
                        fontSize: 28, fontWeight: FontWeight.w700,
                        color: widget.isDark ? AppColors.textDark : AppColors.textLight,
                        letterSpacing: -1.5, height: 1,
                      ),
                    ),
                    TextSpan(
                      text: '%',
                      style: GoogleFonts.dmMono(
                        fontSize: 18,
                        color: widget.isDark ? AppColors.textSubDark : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ENTREGUES',
                style: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  letterSpacing: 1.0,
                ),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;  // 0..1
  final Color accent;
  final Color trackColor;
  const _RingPainter({required this.progress, required this.accent, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const strokeWidth = 10.0;
    final r = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track
    canvas.drawArc(
      rect,
      -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Sweep
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi * progress,
        colors: [accent.withOpacity(0.65), accent],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, sweepPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _SubStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SubStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        _fmt(value),
        style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.3),
      ),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: color.withOpacity(0.6), fontWeight: FontWeight.w500, letterSpacing: 0.3)),
    ]);
  }

  String _fmt(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    return v.toString();
  }
}

class _SubStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 20),
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}

// ─── Mini stat card ───────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(value),
            style: GoogleFonts.dmMono(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDark : AppColors.textLight,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5, fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ]),
      ),
    );
  }

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    return v.toString();
  }
}

// ─── Quick action ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.icon, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: primary ? accent.withOpacity(0.10) : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primary ? accent.withOpacity(0.5) : border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: primary ? accent : (isDark ? AppColors.textSubDark : AppColors.textSubLight)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: primary ? accent : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.9,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
    );
  }
}

// ─── Campaign row ─────────────────────────────────────────────────────────────

class _CampaignRow extends StatelessWidget {
  final Campaign campaign;
  final bool isLast;
  const _CampaignRow({required this.campaign, required this.isLast});

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
          border: Border(
            top: BorderSide(color: border),
            bottom: isLast ? BorderSide(color: border) : BorderSide.none,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Left accent strip
            Container(width: 3, color: s.color),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          campaign.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_ch(campaign.channel)} · ${_fmtNum(campaign.sent)} enviadas',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.label.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: s.color, letterSpacing: 0.4,
                      ),
                    ),
                  ]),
                  if (campaign.totalContacts > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 2,
                        color: s.color,
                        backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.07),
                      ),
                    ),
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

  String _ch(String c) => switch (c) {
    'rcs'      => 'RCS',
    'whatsapp' => 'WA',
    _          => 'SMS',
  };

  String _fmtNum(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toString();
  }
}

// ─── Provider card ────────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ProviderCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final green = isDark ? AppColors.greenDark : AppColors.greenLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withOpacity(0.20)),
          ),
          child: Icon(Icons.bolt_rounded, size: 20, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Zenvia', style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          )),
          const SizedBox(height: 1),
          Text('Conectado', style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w500, color: green,
          )),
        ])),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            side: BorderSide(color: border),
            foregroundColor: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Configurar'),
        ),
      ]),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  const _EmptyState({required this.icon, required this.message, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        const SizedBox(height: 12),
        Text(message, style: GoogleFonts.poppins(
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight, fontSize: 14,
        )),
        if (action != null && onAction != null) ...[
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(action!)),
        ],
      ]),
    );
  }
}
