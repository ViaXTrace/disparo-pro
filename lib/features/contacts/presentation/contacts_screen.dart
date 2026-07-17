import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/contacts_providers.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final contacts = ref.watch(contactsStreamProvider);
    final groups   = ref.watch(contactGroupsStreamProvider);
    final countAsync = ref.watch(contactCountProvider);

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
                      'Contatos',
                      style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                        letterSpacing: -0.6, height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    countAsync.when(
                      data: (n) => RichText(text: TextSpan(children: [
                        TextSpan(
                          text: _fmtNum(n),
                          style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w700, color: accent),
                        ),
                        TextSpan(
                          text: ' cadastrados',
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
                // Import button
                FilledButton.icon(
                  onPressed: () => context.go('/contacts/import'),
                  icon: const Icon(Icons.upload_file_rounded, size: 15),
                  label: Text('Importar', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    minimumSize: Size.zero,
                  ),
                ),
              ]),
            ),
          ),

          // ── Group stats ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverToBoxAdapter(
              child: groups.when(
                data: (list) => list.isEmpty ? const SizedBox.shrink() : _GroupStatsRow(groups: list, ref: ref),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Tab row ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                _Tab(label: 'Todos',  active: _tab == 0, onTap: () => setState(() => _tab = 0)),
                const SizedBox(width: 8),
                _Tab(label: 'Grupos', active: _tab == 1, onTap: () => setState(() => _tab = 1)),
              ]),
            ),
          ),

          // ── Search (Todos tab) ────────────────────────────────────
          if (_tab == 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _SearchBar(
                  onChanged: (v) => ref.read(contactSearchProvider.notifier).state = v,
                  isDark: isDark,
                ),
              ),
            ),

          // ── Section label ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                (_tab == 0 ? 'Todos os contatos' : 'Grupos').toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.9,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────
          if (_tab == 0)
            contacts.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(message: 'Nenhum contato encontrado'),
                  );
                }
                return SliverList.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ContactRow(contact: list[i], ref: ref, idx: i),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
              ),
              error: (e, _) => SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('$e'))),
            )
          else
            groups.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(
                      message: 'Nenhum grupo criado',
                      action: FilledButton.icon(
                        onPressed: () => _showCreateGroup(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: const Text('Criar grupo'),
                      ),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => _GroupRow(group: list[i], ref: ref),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
              ),
              error: (e, _) => SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('$e'))),
            ),

          SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16)),
        ],
      ),
    );
  }

  Future<void> _showCreateGroup(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Novo grupo', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Nome do grupo'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Criar')),
        ],
      ),
    );
    if (ok == true && ctrl.text.isNotEmpty) {
      await ref.read(contactRepositoryProvider).createGroup(name: ctrl.text.trim());
    }
    ctrl.dispose();
  }
}

String _fmtNum(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000)    return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
  return v.toString();
}

// ─── Group stats row ──────────────────────────────────────────────────────────

// 6 rotating avatar colors — same palette as mockup
const _kAvatarColors = [
  Color(0xFF818CF8), Color(0xFF34D399), Color(0xFFFBBF24),
  Color(0xFFF87171), Color(0xFFA78BFA), Color(0xFF60A5FA),
];

class _GroupStatsRow extends StatelessWidget {
  final List<ContactGroup> groups;
  final WidgetRef ref;
  const _GroupStatsRow({required this.groups, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shown = groups.take(3).toList();
    return Row(
      children: List.generate(shown.length, (i) {
        final g = shown[i];
        final color = _kAvatarColors[i % _kAvatarColors.length];
        final countAsync = ref.watch(groupContactCountProvider(g.id));
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < shown.length - 1 ? 8 : 0),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              countAsync.when(
                data: (n) => Text(
                  _fmtNum(n),
                  style: GoogleFonts.dmMono(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5,
                  ),
                ),
                loading: () => Text('—', style: GoogleFonts.dmMono(fontSize: 18, color: color)),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 2),
              Text(g.name, style: GoogleFonts.poppins(
                fontSize: 10.5, fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              )),
            ]),
          ),
        );
      }),
    );
  }
}

// ─── Contact row ──────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final Contact contact;
  final WidgetRef ref;
  final int idx;
  const _ContactRow({required this.contact, required this.ref, required this.idx});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = _kAvatarColors[idx % _kAvatarColors.length];
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final initials = contact.name.isNotEmpty
        ? contact.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Dismissible(
      key: ValueKey(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: isDark ? AppColors.redDark.withOpacity(0.15) : AppColors.redLight.withOpacity(0.10),
        child: Icon(Icons.delete_outline_rounded, color: isDark ? AppColors.redDark : AppColors.redLight, size: 22),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref.read(contactRepositoryProvider).delete(contact.id),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(children: [
            // Avatar
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(initials, style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w800, color: color,
              )),
            ),
            const SizedBox(width: 14),
            // Name + phone
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  contact.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  contact.phone,
                  style: GoogleFonts.dmMono(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ]),
            ),
            // Opt-out badge or nothing
            if (contact.optedOut) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.redDark : AppColors.redLight).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('opt-out', style: GoogleFonts.poppins(
                  fontSize: 9.5, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.redDark : AppColors.redLight,
                  letterSpacing: 0.2,
                )),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Remover contato?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      content: Text('Esta ação não pode ser desfeita.', style: GoogleFonts.poppins()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.redDark : AppColors.redLight,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remover'),
        ),
      ],
    ),
  );
}

// ─── Group row ────────────────────────────────────────────────────────────────

class _GroupRow extends StatelessWidget {
  final ContactGroup group;
  final WidgetRef ref;
  const _GroupRow({required this.group, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countAsync = ref.watch(groupContactCountProvider(group.id));
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.group_outlined,
              size: 20,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(group.name, style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              )),
              const SizedBox(height: 2),
              countAsync.when(
                data: (n) => Text('$n contatos', style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                )),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ]),
          ),
          IconButton(
            onPressed: () => ref.read(contactRepositoryProvider).deleteGroup(group.id),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Tab pill ─────────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
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
        child: Text(label, style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: active ? Colors.white : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
        )),
      ),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final bool isDark;
  const _SearchBar({required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar por nome ou telefone…',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13.5,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ─── Empty ────────────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final String message;
  final Widget? action;
  const _Empty({required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(
        Icons.people_outline_rounded,
        size: 48,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
      const SizedBox(height: 12),
      Text(message, style: GoogleFonts.poppins(
        fontSize: 14,
        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
      )),
      if (action != null) ...[const SizedBox(height: 16), action!],
    ]);
  }
}
