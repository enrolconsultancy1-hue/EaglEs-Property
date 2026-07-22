enum TenantRole {
  tenantOwner,
  orgAdmin,
  manager,
  sales,
  finance,
  marketing,
  constructionManager,
  siteEngineer,
  architect,
  lawyer,
  propertyManager,
  tenantResident,
  buyer,
  investor,
  guest;

  static TenantRole fromString(String val) {
    return TenantRole.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TenantRole.guest,
    );
  }
}

enum PlatformRole {
  superAdmin,
  platformAdmin;

  static PlatformRole? fromString(String val) {
    try {
      return PlatformRole.values.firstWhere(
        (e) => e.name.toLowerCase() == val.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
