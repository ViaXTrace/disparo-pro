import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/contacts',
            name: 'contacts',
            builder: (context, state) => const ContactsScreen(),
            routes: [
              GoRoute(
                path: 'import',
                name: 'contacts-import',
                builder: (context, state) => const ContactImportScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/campaigns',
            name: 'campaigns',
            builder: (context, state) => const CampaignsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'campaign-new',
                builder: (context, state) => const CampaignFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'campaign-detail',
                builder: (context, state) =>
                    CampaignDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/templates',
            name: 'templates',
            builder: (context, state) => const TemplatesScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'template-new',
                builder: (context, state) => const TemplateFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'template-edit',
                builder: (context, state) =>
                    TemplateFormScreen(id: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/providers',
            name: 'providers',
            builder: (context, state) => const ProvidersScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'provider-new',
                builder: (context, state) => const ProviderFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'provider-edit',
                builder: (context, state) =>
                    ProviderFormScreen(id: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
