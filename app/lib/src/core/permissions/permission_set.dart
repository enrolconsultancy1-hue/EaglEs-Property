import 'role_catalog.dart';

class PermissionSet {
  final Set<TenantRole> roles;
  final PlatformRole? platformRole;

  const PermissionSet({
    required this.roles,
    this.platformRole,
  });

  factory PermissionSet.fromRoles(List<String> roleStrings, {String? platformRoleString}) {
    final tenantRoles = roleStrings.map(TenantRole.fromString).toSet();
    final pltRole = platformRoleString != null ? PlatformRole.fromString(platformRoleString) : null;
    return PermissionSet(roles: tenantRoles, platformRole: pltRole);
  }

  bool get isSuperAdmin => platformRole == PlatformRole.superAdmin;
  bool get isPlatformAdmin => platformRole != null;

  bool get canManageTenantSettings =>
      isSuperAdmin || roles.contains(TenantRole.tenantOwner) || roles.contains(TenantRole.orgAdmin);

  bool get canAccessFinancials =>
      isSuperAdmin ||
      roles.contains(TenantRole.tenantOwner) ||
      roles.contains(TenantRole.orgAdmin) ||
      roles.contains(TenantRole.finance);

  bool get canAccessConstruction =>
      isSuperAdmin ||
      roles.contains(TenantRole.tenantOwner) ||
      roles.contains(TenantRole.orgAdmin) ||
      roles.contains(TenantRole.constructionManager) ||
      roles.contains(TenantRole.siteEngineer) ||
      roles.contains(TenantRole.architect);

  bool get canAccessCRM =>
      isSuperAdmin ||
      roles.contains(TenantRole.tenantOwner) ||
      roles.contains(TenantRole.orgAdmin) ||
      roles.contains(TenantRole.manager) ||
      roles.contains(TenantRole.sales) ||
      roles.contains(TenantRole.marketing);

  bool get canAccessProperties => true; // Everyone can view properties according to role rules
}
