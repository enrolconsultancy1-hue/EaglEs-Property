import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_paths.dart';
import '../../../main.dart'; // WorkspaceShell
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/construction/presentation/construction_screen.dart';
import '../../features/crm/presentation/crm_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';
import '../../features/ai_assistant/presentation/mr_eagles_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.dashboard,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => WorkspaceShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RoutePaths.projects,
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: RoutePaths.inventory,
            builder: (context, state) => const ProjectsScreen(), // Sub-tab of projects/inventory
          ),
          GoRoute(
            path: '/construction',
            builder: (context, state) => const ConstructionScreen(),
          ),
          GoRoute(
            path: '/sales-crm',
            builder: (context, state) => const CRMScreen(),
          ),
          GoRoute(
            path: '/marketplace',
            builder: (context, state) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: '/mr-eagles',
            builder: (context, state) => const MrEaglesScreen(),
          ),
          GoRoute(
            path: RoutePaths.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
