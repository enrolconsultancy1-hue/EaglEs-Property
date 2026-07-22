import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Projects & Inventory',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('New Project'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: const [
                  _ProjectCard(
                    title: 'Bole Sky Towers',
                    location: 'Bole Sub-city, Addis Ababa',
                    type: 'Mixed-Use Residential & Commercial',
                    unitsTotal: 320,
                    unitsAvailable: 104,
                    progress: 0.65,
                  ),
                  SizedBox(height: 16),
                  _ProjectCard(
                    title: 'Summit Gardens Villas',
                    location: 'Summit District, Addis Ababa',
                    type: 'Gated Luxury Residential Community',
                    unitsTotal: 85,
                    unitsAvailable: 12,
                    progress: 0.88,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final String location;
  final String type;
  final int unitsTotal;
  final int unitsAvailable;
  final double progress;

  const _ProjectCard({
    required this.title,
    required this.location,
    required this.type,
    required this.unitsTotal,
    required this.unitsAvailable,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text('$unitsAvailable Available'),
                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$type • $location',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toInt()}% Built',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
