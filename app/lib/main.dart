import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: EaglesPropertyApp()));
}

class EaglesPropertyApp extends StatelessWidget {
  const EaglesPropertyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EaglEs Property',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF356B5A)),
        useMaterial3: true,
      ),
      home: const SessionGate(),
    );
  }
}

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    return session.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Session error: $error'))),
      data: (state) => state.isAuthenticated
          ? const WorkspaceShell()
          : const SignInPlaceholder(),
    );
  }
}

class SignInPlaceholder extends StatelessWidget {
  const SignInPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
          ),
          icon: const Icon(Icons.login),
          label: const Text('Sign in to EaglEs Property'),
        ),
      ),
    );
  }
}

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).signIn(emailController.text.trim(), passwordController.text);
              if (context.mounted && ref.read(sessionControllerProvider).hasValue) Navigator.of(context).pop();
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

class WorkspaceShell extends ConsumerStatefulWidget {
  const WorkspaceShell({super.key});

  @override
  ConsumerState<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends ConsumerState<WorkspaceShell> {
  int index = 0;

  static const destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.apartment_outlined), label: 'Properties'),
    NavigationDestination(icon: Icon(Icons.people_outline), label: 'Sales CRM'),
    NavigationDestination(icon: Icon(Icons.account_balance_outlined), label: 'Finance'),
  ];

  @override
  Widget build(BuildContext context) {
    final sessionValue = ref.watch(sessionControllerProvider).valueOrNull;
    if (sessionValue == null || !sessionValue.isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final session = sessionValue;
    final pages = [
      DashboardPage(session: session),
      const PropertiesPage(),
      const SalesCrmPage(),
      const FinancePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(session.tenantName),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.business_outlined),
            onSelected: (tenantId) => ref.read(sessionControllerProvider.notifier).switchTenant(tenantId),
            itemBuilder: (_) => session.tenants
                .map((tenant) => PopupMenuItem(value: tenant.id, child: Text(tenant.name)))
                .toList(),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: destinations,
        onDestinationSelected: (value) => setState(() => index = value),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({required this.session, super.key});
  final SessionState session;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Good morning', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('${session.role} · ${session.tenantName}'),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            MetricCard(label: 'Available units', value: '—', icon: Icons.grid_view),
            MetricCard(label: 'Active leads', value: '—', icon: Icons.people),
            MetricCard(label: 'Reservations', value: '—', icon: Icons.bookmark_added),
          ],
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.label, required this.value, required this.icon, super.key});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon),
            const SizedBox(height: 18),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ]),
        ),
      ),
    );
  }
}

class PropertiesPage extends StatelessWidget {
  const PropertiesPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Projects and unit inventory'));
}

class SalesCrmPage extends StatelessWidget {
  const SalesCrmPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Lead pipeline and reservations'));
}

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Finance is planned for Phase 2'));
}
