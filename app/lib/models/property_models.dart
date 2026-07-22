enum UnitStatus { available, reserved, sold, blocked }

enum LeadStage { newLead, qualified, siteVisit, negotiation, reservation, closedLost }

extension UnitStatusLabel on UnitStatus {
  String get label => switch (this) {
        UnitStatus.available => 'Available',
        UnitStatus.reserved => 'Reserved',
        UnitStatus.sold => 'Sold',
        UnitStatus.blocked => 'Blocked',
      };
}

extension LeadStageLabel on LeadStage {
  String get label => switch (this) {
        LeadStage.newLead => 'New',
        LeadStage.qualified => 'Qualified',
        LeadStage.siteVisit => 'Site visit',
        LeadStage.negotiation => 'Negotiation',
        LeadStage.reservation => 'Reservation',
        LeadStage.closedLost => 'Closed lost',
      };
}

class Tenant {
  const Tenant({
    required this.id,
    required this.name,
    required this.currency,
    this.logoUrl,
    this.brandColorHex,
    this.secondaryColorHex,
  });

  final String id;
  final String name;
  final String currency;
  final String? logoUrl;
  final String? brandColorHex;
  final String? secondaryColorHex;
}

class Project {
  const Project({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.location,
    required this.status,
    required this.towerCount,
    required this.totalUnits,
    required this.units,
  });

  final String id;
  final String tenantId;
  final String name;
  final String location;
  final String status;
  final int towerCount;
  final int totalUnits;
  final List<Unit> units;
}

class Unit {
  const Unit({
    required this.id,
    required this.projectId,
    required this.number,
    required this.tower,
    required this.floor,
    required this.type,
    required this.area,
    required this.price,
    required this.status,
    this.currentLeadId,
  });

  final String id;
  final String projectId;
  final String number;
  final String tower;
  final int floor;
  final String type;
  final int area;
  final int price;
  final UnitStatus status;
  final String? currentLeadId;

  Unit copyWith({UnitStatus? status, String? currentLeadId}) => Unit(
        id: id,
        projectId: projectId,
        number: number,
        tower: tower,
        floor: floor,
        type: type,
        area: area,
        price: price,
        status: status ?? this.status,
        currentLeadId: currentLeadId ?? this.currentLeadId,
      );
}

class Lead {
  const Lead({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.email,
    required this.phone,
    required this.source,
    required this.budget,
    required this.interestedProjectId,
    required this.stage,
    required this.score,
    required this.assignedAgent,
    this.reservedUnitId,
  });

  final String id;
  final String tenantId;
  final String name;
  final String email;
  final String phone;
  final String source;
  final int budget;
  final String interestedProjectId;
  final LeadStage stage;
  final int score;
  final String assignedAgent;
  final String? reservedUnitId;

  Lead copyWith({LeadStage? stage, String? reservedUnitId}) => Lead(
        id: id,
        tenantId: tenantId,
        name: name,
        email: email,
        phone: phone,
        source: source,
        budget: budget,
        interestedProjectId: interestedProjectId,
        stage: stage ?? this.stage,
        score: score,
        assignedAgent: assignedAgent,
        reservedUnitId: reservedUnitId ?? this.reservedUnitId,
      );
}
