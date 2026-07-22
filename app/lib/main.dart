import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'src/core/router/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'data/providers.dart';

void main() => runApp(const ProviderScope(child: EaglesPropertyApp()));

class EaglesPropertyApp extends ConsumerWidget {
  const EaglesPropertyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final tenantId = ref.watch(activeTenantProvider);
    final tenant = ref.watch(propertyRepositoryProvider).tenants.firstWhere((t) => t.id == tenantId);
    
    Color? brandColor;
    if (tenant.brandColorHex != null) {
      brandColor = Color(int.parse('0xFF${tenant.brandColorHex}'));
    }

    return MaterialApp.router(
      title: 'EaglEs Property',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(brandColor),
      darkTheme: AppTheme.darkTheme(brandColor),
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
        Locale('ti'),
        Locale('om'),
      ],
      locale: const Locale('en'),
    );
  }
}

class WorkspaceShell extends ConsumerWidget {
  const WorkspaceShell({required this.child, super.key});
  final Widget child;

  static const destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.apartment_outlined), label: 'Properties'),
    NavigationDestination(icon: Icon(Icons.construction_outlined), label: 'Construction'),
    NavigationDestination(icon: Icon(Icons.people_outline), label: 'Sales CRM'),
    NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Marketplace'),
    NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Mr. EaglEs'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(activeTenantProvider);
    final tenant = ref.watch(propertyRepositoryProvider).tenants.firstWhere((item) => item.id == tenantId);
    
    final location = GoRouterState.of(context).uri.toString();
    final index = _getSelectedIndex(location);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (tenant.logoUrl != null) ...[
              CircleAvatar(
                backgroundImage: NetworkImage(tenant.logoUrl!),
                radius: 16,
              ),
              const SizedBox(width: 8),
            ],
            Text(tenant.name),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Switch workspace',
            icon: const Icon(Icons.business_outlined),
            onSelected: (value) {
              ref.read(activeTenantProvider.notifier).state = value;
              ref.read(selectedProjectProvider.notifier).state = value == 'eagles' ? 'eagle-heights' : 'summit-gardens';
            },
            itemBuilder: (_) => ref.watch(propertyRepositoryProvider).tenants.map((item) => PopupMenuItem(value: item.id, child: Text(item.name))).toList(),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: destinations,
        onDestinationSelected: (value) => _onDestinationSelected(context, value),
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/app/dashboard') || location == '/dashboard') return 0;
    if (location.startsWith('/app/projects') || location == '/properties') return 1;
    if (location.startsWith('/construction')) return 2;
    if (location.startsWith('/sales-crm')) return 3;
    if (location.startsWith('/marketplace')) return 4;
    if (location.startsWith('/mr-eagles')) return 5;
    if (location.startsWith('/app/settings') || location == '/settings') return 6;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/app/dashboard'); break;
      case 1: context.go('/app/projects'); break;
      case 2: context.go('/construction'); break;
      case 3: context.go('/sales-crm'); break;
      case 4: context.go('/marketplace'); break;
      case 5: context.go('/mr-eagles'); break;
      case 6: context.go('/app/settings'); break;
    }
  }
}