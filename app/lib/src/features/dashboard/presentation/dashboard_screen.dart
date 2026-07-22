import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Executive Dashboard',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Real-time overview of portfolio performance, revenue, and construction progress.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // KPI Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.2,
                  children: const [
                    _KpiCard(
                      title: 'TOTAL REVENUE',
                      value: '\$4.2M',
                      trend: '▲ 12.4%',
                      isPositive: true,
                    ),
                    _KpiCard(
                      title: 'UNITS SOLD',
                      value: '214 / 620',
                      trend: '34.5% Total',
                      isPositive: true,
                    ),
                    _KpiCard(
                      title: 'OCCUPANCY RATE',
                      value: '87.3%',
                      trend: '▲ 2.1%',
                      isPositive: true,
                    ),
                    _KpiCard(
                      title: 'CONSTRUCTION PROGRESS',
                      value: '43.5%',
                      trend: 'SPI 0.94',
                      isPositive: false,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mr. EaglEs AI Insights',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          avatar: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Live Feed'),
                          backgroundColor: theme.colorScheme.primaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      title: Text('Tower 2 Construction Delay Risk'),
                      subtitle: Text('Material delivery delay increased schedule risk to 31%. Mitigation plan recommended.'),
                    ),
                    const Divider(),
                    const ListTile(
                      leading: Icon(Icons.local_fire_department, color: Colors.redAccent),
                      title: Text('Hot Lead Detected: A. Tesfaye'),
                      subtitle: Text('Lead engagement score: 87/100. High probability of closing Bole Sky Tower 3BR.'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: isPositive ? Colors.green.shade700 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
