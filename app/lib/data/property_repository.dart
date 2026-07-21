import '../models/property_models.dart';

abstract class PropertyRepository {
  List<Tenant> get tenants;
  List<Project> projectsForTenant(String tenantId);
  List<Lead> leadsForTenant(String tenantId);
  Unit? findUnit(String tenantId, String unitId);
  void updateUnitStatus(String tenantId, String unitId, UnitStatus status);
  void updateLeadStage(String tenantId, String leadId, LeadStage stage);
  void reserveUnit({required String tenantId, required String leadId, required String unitId});
}

class MockPropertyRepository implements PropertyRepository {
  MockPropertyRepository() {
    _seed();
  }

  final List<Tenant> _tenants = const [
    Tenant(id: 'eagles', name: 'EaglEs Development Group', currency: 'ETB'),
    Tenant(id: 'summit', name: 'Summit Properties', currency: 'USD'),
  ];
  final List<Project> _projects = [];
  final List<Lead> _leads = [];

  @override
  List<Tenant> get tenants => List.unmodifiable(_tenants);

  @override
  List<Project> projectsForTenant(String tenantId) => _projects.where((p) => p.tenantId == tenantId).toList();

  @override
  List<Lead> leadsForTenant(String tenantId) => _leads.where((lead) => lead.tenantId == tenantId).toList();

  @override
  Unit? findUnit(String tenantId, String unitId) {
    for (final project in projectsForTenant(tenantId)) {
      for (final unit in project.units) {
        if (unit.id == unitId) return unit;
      }
    }
    return null;
  }

  @override
  void updateUnitStatus(String tenantId, String unitId, UnitStatus status) {
    _replaceUnit(tenantId, unitId, (unit) => unit.copyWith(status: status));
  }

  @override
  void updateLeadStage(String tenantId, String leadId, LeadStage stage) {
    final index = _leads.indexWhere((lead) => lead.tenantId == tenantId && lead.id == leadId);
    if (index >= 0) _leads[index] = _leads[index].copyWith(stage: stage);
  }

  @override
  void reserveUnit({required String tenantId, required String leadId, required String unitId}) {
    _replaceUnit(tenantId, unitId, (unit) => unit.copyWith(status: UnitStatus.reserved, currentLeadId: leadId));
    updateLeadStage(tenantId, leadId, LeadStage.reservation);
    final index = _leads.indexWhere((lead) => lead.tenantId == tenantId && lead.id == leadId);
    if (index >= 0) _leads[index] = _leads[index].copyWith(reservedUnitId: unitId);
  }

  void _replaceUnit(String tenantId, String unitId, Unit Function(Unit) update) {
    final projectIndex = _projects.indexWhere((project) => project.tenantId == tenantId && project.units.any((unit) => unit.id == unitId));
    if (projectIndex < 0) return;
    final project = _projects[projectIndex];
    final units = project.units.map((unit) => unit.id == unitId ? update(unit) : unit).toList();
    _projects[projectIndex] = Project(
      id: project.id,
      tenantId: project.tenantId,
      name: project.name,
      location: project.location,
      status: project.status,
      towerCount: project.towerCount,
      totalUnits: project.totalUnits,
      units: units,
    );
  }

  void _seed() {
    final eaglesUnits = <Unit>[
      const Unit(id: 'e-101', projectId: 'eagle-heights', number: 'A-101', tower: 'A', floor: 1, type: '2BR', area: 84, price: 4200000, status: UnitStatus.available),
      const Unit(id: 'e-102', projectId: 'eagle-heights', number: 'A-102', tower: 'A', floor: 1, type: '1BR', area: 58, price: 2950000, status: UnitStatus.reserved, currentLeadId: 'lead-1'),
      const Unit(id: 'e-201', projectId: 'eagle-heights', number: 'A-201', tower: 'A', floor: 2, type: '3BR', area: 126, price: 6300000, status: UnitStatus.available),
      const Unit(id: 'e-202', projectId: 'eagle-heights', number: 'A-202', tower: 'A', floor: 2, type: '2BR', area: 84, price: 4200000, status: UnitStatus.sold),
      const Unit(id: 'e-301', projectId: 'eagle-heights', number: 'B-301', tower: 'B', floor: 3, type: '2BR', area: 86, price: 4550000, status: UnitStatus.available),
      const Unit(id: 'e-302', projectId: 'eagle-heights', number: 'B-302', tower: 'B', floor: 3, type: '1BR', area: 60, price: 3100000, status: UnitStatus.blocked),
    ];
    _projects.add(Project(id: 'eagle-heights', tenantId: 'eagles', name: 'Eagle Heights', location: 'Bole, Addis Ababa', status: 'In progress', towerCount: 2, totalUnits: eaglesUnits.length, units: eaglesUnits));
    _projects.add(const Project(id: 'summit-gardens', tenantId: 'summit', name: 'Summit Gardens', location: 'Kazanchis, Addis Ababa', status: 'Planning', towerCount: 3, totalUnits: 0, units: []));
    _leads.addAll([
      const Lead(id: 'lead-1', tenantId: 'eagles', name: 'Marta Bekele', email: 'marta@example.com', phone: '+251 911 000 101', source: 'Web', budget: 4500000, interestedProjectId: 'eagle-heights', stage: LeadStage.reservation, score: 88, assignedAgent: 'Dawit Tesfaye', reservedUnitId: 'e-102'),
      const Lead(id: 'lead-2', tenantId: 'eagles', name: 'Daniel Kassa', email: 'daniel@example.com', phone: '+251 911 000 202', source: 'Referral', budget: 6500000, interestedProjectId: 'eagle-heights', stage: LeadStage.negotiation, score: 76, assignedAgent: 'Dawit Tesfaye'),
      const Lead(id: 'lead-3', tenantId: 'eagles', name: 'Hana Worku', email: 'hana@example.com', phone: '+251 911 000 303', source: 'Walk-in', budget: 3200000, interestedProjectId: 'eagle-heights', stage: LeadStage.siteVisit, score: 64, assignedAgent: 'Selam Girma'),
      const Lead(id: 'lead-4', tenantId: 'eagles', name: 'Samuel Abebe', email: 'samuel@example.com', phone: '+251 911 000 404', source: 'Social', budget: 3000000, interestedProjectId: 'eagle-heights', stage: LeadStage.qualified, score: 52, assignedAgent: 'Selam Girma'),
      const Lead(id: 'lead-5', tenantId: 'eagles', name: 'Liya Tadesse', email: 'liya@example.com', phone: '+251 911 000 505', source: 'Web', budget: 5000000, interestedProjectId: 'eagle-heights', stage: LeadStage.newLead, score: 38, assignedAgent: 'Unassigned'),
    ]);
  }
}
