import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/campaigns/presentation/campaign_detail_screen.dart';
import '../../features/campaigns/presentation/campaign_form_screen.dart';
import '../../features/campaigns/presentation/campaigns_screen.dart';
import '../../features/contacts/presentation/contact_import_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/providers/presentation/provider_form_screen.dart';
import '../../features/providers/presentation/providers_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/templates/presentation/template_form_screen.dart';
import '../../features/templates/presentation/templates_screen.dart';
import '../shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', name: 'dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(
            path: '/contacts',
            name: 'contacts',
            builder: (_, __) => const ContactsScreen(),
            routes: [
              GoRoute(path: 'import', name: 'contacts-import', builder: (_, __) => const ContactImportScreen()),
            ],
          ),
          GoRoute(
            path: '/campaigns',
            name: 'campaigns',
            builder: (_, __) => const CampaignsScreen(),
            routes: [
              GoRoute(path: 'new', name: 'campaign-new', builder: (_, __) => const CampaignFormScreen()),
              GoRoute(
                path: ':id',
                name: 'campaign-detail',
                builder: (_, state) => CampaignDetailScreen(id: int.parse(state.pathParameters['id']!)),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'campaign-edit',
                builder: (_, state) => CampaignFormScreen(id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/templates',
            name: 'templates',
            builder: (_, __) => const TemplatesScreen(),
            routes: [
              GoRoute(path: 'new', name: 'template-new', builder: (_, __) => const TemplateFormScreen()),
              GoRoute(
                path: ':id/edit',
                name: 'template-edit',
                builder: (_, state) => TemplateFormScreen(id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/providers',
            name: 'providers',
            builder: (_, __) => const ProvidersScreen(),
            routes: [
              GoRoute(path: 'new', name: 'provider-new', builder: (_, __) => const ProviderFormScreen()),
              GoRoute(
                path: ':id/edit',
                name: 'provider-edit',
                builder: (_, state) => ProviderFormScreen(id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(path: '/reports', name: 'reports', builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/settings', name: 'settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
