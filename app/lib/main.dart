import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'models/property_models.dart';

void main() => runApp(const ProviderScope(child: EaglesPropertyApp()));

class EaglesPropertyApp extends StatelessWidget {
  const EaglesPropertyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'EaglEs Property',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF356B5A)), useMaterial3: true),
        home: const WorkspaceShell(),
      );
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
    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final tenantId = ref.watch(activeTenantProvider);
    final tenant = ref.watch(propertyRepositoryProvider).tenants.firstWhere((item) => item.id == tenantId);
    final pages = [const DashboardPage(), const PropertiesPage(), const SalesCrmPage(), const SettingsPage()];

    return Scaffold(
      appBar: AppBar(
        title: Text(tenant.name),
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
      body: pages[index],
      bottomNavigationBar: NavigationBar(selectedIndex: index, destinations: destinations, onDestinationSelected: (value) => setState(() => index = value)),
    );
  }
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    final leads = ref.watch(tenantLeadsProvider);
    final units = projects.expand((project) => project.units).toList();
    final available = units.where((unit) => unit.status == UnitStatus.available).length;
    final reserved = units.where((unit) => unit.status == UnitStatus.reserved).length;
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text('Mission control', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text('A clear view of your developer-sales workflow.', style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 24),
      Wrap(spacing: 12, runSpacing: 12, children: [
        MetricCard(label: 'Available units', value: '$available', icon: Icons.grid_view, color: Colors.teal),
        MetricCard(label: 'Active leads', value: '${leads.length}', icon: Icons.people_outline, color: Colors.blue),
        MetricCard(label: 'Reservations', value: '$reserved', icon: Icons.bookmark_added_outlined, color: Colors.orange),
        MetricCard(label: 'Projects', value: '${projects.length}', icon: Icons.apartment_outlined, color: Colors.indigo),
      ]),
      const SizedBox(height: 28),
      Text('Priority actions', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      ActionCard(icon: Icons.people_outline, title: 'Review the sales pipeline', subtitle: 'Move qualified prospects toward a reservation.', onTap: () {}),
      ActionCard(icon: Icons.grid_view, title: 'Check inventory availability', subtitle: 'Keep unit status accurate for every conversation.', onTap: () {}),
    ]);
  }
}

class PropertiesPage extends ConsumerWidget {
  const PropertiesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    return ListView(padding: const EdgeInsets.all(24), children: [
      PageHeader(title: 'Properties', subtitle: 'Projects, towers, floors, and unit availability.'),
      const SizedBox(height: 16),
      ...projects.map((project) => ProjectCard(project: project)),
    ]);
  }
}

class ProjectCard extends ConsumerWidget {
  const ProjectCard({required this.project, super.key});
  final Project project;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = project.units.where((unit) => unit.status == UnitStatus.available).length;
    final selected = ref.watch(selectedProjectProvider) == project.id;
    return Card(
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(selectedProjectProvider.notifier).state = project.id,
        child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(project.name, style: Theme.of(context).textTheme.titleLarge)), Chip(label: Text(project.status))]),
          const SizedBox(height: 6), Text(project.location),
          const SizedBox(height: 14),
          Row(children: [Text('${project.towerCount} towers'), const SizedBox(width: 18), Text('${project.totalUnits} units'), const SizedBox(width: 18), Text('$available available')]),
          if (project.units.isNotEmpty) ...[
            const SizedBox(height: 16),
            UnitMatrix(project: project),
          ],
        ]),
      ),
    );
  }
}

class UnitMatrix extends ConsumerWidget {
  const UnitMatrix({required this.project, super.key});
  final Project project;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(propertyRepositoryProvider);
    return Wrap(spacing: 8, runSpacing: 8, children: project.units.map((unit) => Tooltip(
      message: '${unit.number} · ${unit.type} · ${unit.price} · ${unit.status.label}',
      child: InkWell(
        onTap: unit.status == UnitStatus.available ? () => _showUnitActions(context, ref, unit) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(width: 72, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6), decoration: BoxDecoration(color: statusColor(unit.status).withOpacity(.14), border: Border.all(color: statusColor(unit.status)), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text(unit.number, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(unit.status.label, style: TextStyle(fontSize: 10, color: statusColor(unit.status)))])),
      ),
    )).toList());
  }

  void _showUnitActions(BuildContext context, WidgetRef ref, Unit unit) {
    showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.info_outline), title: Text('${unit.number} · ${unit.type}'), subtitle: Text('${unit.area} sqm · ${unit.price}')),
      ListTile(leading: const Icon(Icons.block_outlined), title: const Text('Block unit'), onTap: () { ref.read(propertyRepositoryProvider).updateUnitStatus(ref.read(activeTenantProvider), unit.id, UnitStatus.blocked); ref.read(refreshTokenProvider.notifier).state++; Navigator.pop(context); }),
    ])));
  }
}

class SalesCrmPage extends ConsumerWidget {
  const SalesCrmPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leads = ref.watch(tenantLeadsProvider);
    return ListView(padding: const EdgeInsets.all(24), children: [
      PageHeader(title: 'Sales CRM', subtitle: 'Track every lead from first contact to reservation.'),
      const SizedBox(height: 16),
      SizedBox(height: 510, child: ListView( scrollDirection: Axis.horizontal, children: LeadStage.values.map((stage) => PipelineColumn(stage: stage, leads: leads.where((lead) => lead.stage == stage).toList())).toList())),
    ]);
  }
}

class PipelineColumn extends ConsumerWidget {
  const PipelineColumn({required this.stage, required this.leads, super.key});
  final LeadStage stage;
  final List<Lead> leads;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(width: 245, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.5), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(stage.label, style: const TextStyle(fontWeight: FontWeight.w600))), CircleAvatar(radius: 12, child: Text('${leads.length}', style: const TextStyle(fontSize: 12)))]),
    const SizedBox(height: 12),
    Expanded(child: ListView(children: leads.map((lead) => LeadCard(lead: lead)).toList())),
  ]));
}

class LeadCard extends ConsumerWidget {
  const LeadCard({required this.lead, super.key});
  final Lead lead;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(margin: const EdgeInsets.only(bottom: 10), child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => showDialog<void>(context: context, builder: (_) => LeadDetailsDialog(lead: lead)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(lead.name, style: const TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 4), Text(lead.source, style: Theme.of(context).textTheme.bodySmall),
    const SizedBox(height: 12), Row(children: [Expanded(child: LinearProgressIndicator(value: lead.score / 100)), const SizedBox(width: 8), Text('${lead.score}')]),
    const SizedBox(height: 10), DropdownButtonHideUnderline(child: DropdownButton<LeadStage>(isDense: true, value: lead.stage, isExpanded: true, onChanged: (stage) { if (stage != null) { ref.read(propertyRepositoryProvider).updateLeadStage(lead.tenantId, lead.id, stage); ref.read(refreshTokenProvider.notifier).state++; } }, items: LeadStage.values.map((stage) => DropdownMenuItem(value: stage, child: Text(stage.label))).toList())),
  ]))));
}

class LeadDetailsDialog extends ConsumerWidget {
  const LeadDetailsDialog({required this.lead, super.key});
  final Lead lead;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(propertyRepositoryProvider).projectsForTenant(lead.tenantId).where((project) => project.id == lead.interestedProjectId).toList();
    final project = projects.isEmpty ? null : projects.first;
    final available = project?.units.where((unit) => unit.status == UnitStatus.available).toList() ?? [];
    return AlertDialog(title: Text(lead.name), content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(lead.email), Text(lead.phone), const SizedBox(height: 12), Text('Budget: ${lead.budget}'), Text('Assigned to: ${lead.assignedAgent}'), if (lead.stage != LeadStage.reservation && available.isNotEmpty) ...[const SizedBox(height: 18), const Text('Reserve an available unit', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 6), DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Unit'), items: available.map((unit) => DropdownMenuItem(value: unit.id, child: Text('${unit.number} · ${unit.type}'))).toList(), onChanged: (unitId) { if (unitId != null) { ref.read(propertyRepositoryProvider).reserveUnit(tenantId: lead.tenantId, leadId: lead.id, unitId: unitId); ref.read(refreshTokenProvider.notifier).state++; Navigator.pop(context); } })]])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]);
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) { final tenantId = ref.watch(activeTenantProvider); final tenant = ref.watch(propertyRepositoryProvider).tenants.firstWhere((item) => item.id == tenantId); return ListView(padding: const EdgeInsets.all(24), children: [PageHeader(title: 'Workspace settings', subtitle: 'Mock mode is active while the frontend is being built.'), const SizedBox(height: 20), Card(child: ListTile(leading: const Icon(Icons.business), title: Text(tenant.name), subtitle: Text('Currency: ${tenant.currency}'))), const SizedBox(height: 12), const Card(child: ListTile(leading: Icon(Icons.cloud_off), title: Text('Firebase integration is paused'), subtitle: Text('The repository and UI contracts are ready for the Firebase adapter.')))]); }
}

class PageHeader extends StatelessWidget { const PageHeader({required this.title, required this.subtitle, super.key}); final String title; final String subtitle; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 6), Text(subtitle)]); }
class ActionCard extends StatelessWidget { const ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap, super.key}); final IconData icon; final String title; final String subtitle; final VoidCallback onTap; @override Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.arrow_forward_ios, size: 16))); }
class MetricCard extends StatelessWidget { const MetricCard({required this.label, required this.value, required this.icon, required this.color, super.key}); final String label; final String value; final IconData icon; final Color color; @override Widget build(BuildContext context) => SizedBox(width: 190, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 14), Text(value, style: Theme.of(context).textTheme.headlineSmall), Text(label)])))); }
Color statusColor(UnitStatus status) => switch (status) { UnitStatus.available => Colors.green, UnitStatus.reserved => Colors.orange, UnitStatus.sold => Colors.blueGrey, UnitStatus.blocked => Colors.red };
