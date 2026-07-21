import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'property_repository.dart';
import '../models/property_models.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) => MockPropertyRepository());

final activeTenantProvider = StateProvider<String>((ref) => 'eagles');

final selectedProjectProvider = StateProvider<String>((ref) => 'eagle-heights');

final projectListProvider = Provider<List<Project>>((ref) {
  ref.watch(refreshTokenProvider);
  final tenantId = ref.watch(activeTenantProvider);
  return ref.watch(propertyRepositoryProvider).projectsForTenant(tenantId);
});

final activeProjectProvider = Provider<Project?>((ref) {
  final projectId = ref.watch(selectedProjectProvider);
  final projects = ref.watch(projectListProvider).where((project) => project.id == projectId).toList();
  return projects.isEmpty ? null : projects.first;
});

final tenantLeadsProvider = Provider<List<Lead>>((ref) {
  ref.watch(refreshTokenProvider);
  final tenantId = ref.watch(activeTenantProvider);
  return ref.watch(propertyRepositoryProvider).leadsForTenant(tenantId);
});

final refreshTokenProvider = StateProvider<int>((ref) => 0);
