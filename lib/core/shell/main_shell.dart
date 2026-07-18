import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex(context);
    final mq = MediaQuery.of(context);
    final bottom = mq.padding.bottom;
    final keyboardOpen = mq.viewInsets.bottom > 0;

    // ──────────────────────────────────────────────────────────────────
    // KEYBOARD FIX
    //
    // When the keyboard is open we MUST:
    //   1. Remove the bottom nav bar completely (bottomNavigationBar = null)
    //   2. NOT use extendBody (no body extension behind a non-existent nav)
    //   3. NOT inject the extra 80 px padding (it would push a black gap below
    //      the keyboard since the inner Scaffold's resizeToAvoidBottomInset
    //      has already shrunk the body)
    //
    // When the keyboard is closed we DO:
    //   1. Show the floating pill nav
    //   2. Use extendBody so content can visually bleed behind the nav pill
    //   3. Inject padding.bottom = 80 + safeArea so inner ListViews can read
    //      it and add the correct bottom inset via MediaQuery.of(context).padding.bottom
    // ──────────────────────────────────────────────────────────────────

    if (keyboardOpen) {
      // Full-screen body, no nav bar, no padding injection — inner Scaffold
      // handles the keyboard resize cleanly with zero interference.
      return Scaffold(
        extendBody: false,
        body: child,
      );
    }

    return Scaffold(
      extendBody: true,
      body: MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(
            bottom: 80 + bottom,
          ),
        ),
        child: child,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 20 + bottom),
        child: _FloatingNav(
          selectedIndex: index,
          onTap: (i) => _onTap(context, i),
        ),
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/contacts'))  return 1;
    if (path.startsWith('/campaigns')) return 2;
    if (path.startsWith('/templates')) return 3;
    if (path.startsWith('/providers') || path.startsWith('/settings')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0: context.go('/dashboard');
      case 1: context.go('/contacts');
      case 2: context.go('/campaigns');
      case 3: context.go('/templates');
      case 4: context.go('/settings');
    }
  }
}

// ─── Floating pill nav ──────────────────────────────────────────────────────

class _FloatingNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _FloatingNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0E0F17).withOpacity(0.82)
                : Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.50 : 0.10),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _NavItem(icon: Icons.grid_view_rounded,      label: 'Início',    active: selectedIndex == 0, accent: accent, onTap: () => onTap(0))),
              Expanded(child: _NavItem(icon: Icons.people_outline_rounded, label: 'Contatos',  active: selectedIndex == 1, accent: accent, onTap: () => onTap(1))),
              Expanded(child: _NavItem(icon: Icons.send_rounded,           label: 'Campanhas', active: selectedIndex == 2, accent: accent, onTap: () => onTap(2))),
              Expanded(child: _NavItem(icon: Icons.article_outlined,       label: 'Templates', active: selectedIndex == 3, accent: accent, onTap: () => onTap(3))),
              Expanded(child: _NavItem(icon: Icons.settings_outlined,      label: 'Config',    active: selectedIndex == 4, accent: accent, onTap: () => onTap(4))),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: active ? accent : mutedColor),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? accent : mutedColor,
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
