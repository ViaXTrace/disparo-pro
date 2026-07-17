import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../templates/providers/templates_providers.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final templates = ref.watch(templatesStreamProvider(null));

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
                      'Templates',
                      style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                        letterSpacing: -0.6, height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    templates.when(
                      data: (list) => RichText(text: TextSpan(children: [
                        TextSpan(
                          text: '${list.length}',
                          style: GoogleFonts.dmMono(
                            fontSize: 13, fontWeight: FontWeight.w700, color: accent,
                          ),
                        ),
                        TextSpan(
                          text: list.length == 1 ? ' salvo' : ' salvos',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ])),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ]),
                ),
                GestureDetector(
                  onTap: () => context.go('/templates/new'),
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

          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          templates.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(onNew: () => context.go('/templates/new')),
                );
              }
              return SliverList.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => _TemplateTile(template: list[i], ref: ref),
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

          SliverPadding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }
}

// ─── Template tile ────────────────────────────────────────────────────────────

class _TemplateTile extends StatelessWidget {
  final Template template;
  final WidgetRef ref;
  const _TemplateTile({required this.template, required this.ref});

  Color _channelColor(String c) => switch (c) {
    'rcs'      => const Color(0xFFA78BFA),
    'whatsapp' => const Color(0xFF34D399),
    'sms'      => const Color(0xFF818CF8),
    _          => const Color(0xFF818CF8),
  };

  String _channelLabel(String c) => switch (c) {
    'rcs'      => 'RCS',
    'whatsapp' => 'WA',
    'sms'      => 'SMS',
    _          => 'TODOS',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final color  = _channelColor(template.channel);

    return InkWell(
      onTap: () => context.go('/templates/${template.id}/edit'),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: border)),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 3, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _channelLabel(template.channel),
                            style: GoogleFonts.dmMono(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: color, letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            template.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5, fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textDark : AppColors.textLight,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Text(
                        template.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          height: 1.4,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(context),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.delete_outline_rounded, size: 17,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir template?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Esta ação não pode ser desfeita.',
          style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
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

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyState({required this.onNew});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(
        Icons.article_outlined,
        size: 44,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
      const SizedBox(height: 12),
      Text('Nenhum template criado', style: GoogleFonts.poppins(
        fontSize: 14,
        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
      )),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: onNew,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Criar template'),
      ),
    ]);
  }
}
