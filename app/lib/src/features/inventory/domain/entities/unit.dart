enum UnitStatus {
  available,
  held,
  reserved,
  sold,
  rented,
  blocked,
  underMaintenance;

  static UnitStatus fromString(String status) {
    return UnitStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => UnitStatus.available,
    );
  }
}

class Unit {
  final String id;
  final String tenantId;
  final String code;
  final String projectId;
  final String buildingId;
  final String floorId;
  final UnitStatus status;
  final int bedrooms;
  final int bathrooms;
  final double areaSqm;
  final double listPrice;
  final String currency;

  const Unit({
    required this.id,
    required this.tenantId,
    required this.code,
    required this.projectId,
    required this.buildingId,
    required this.floorId,
    required this.status,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqm,
    required this.listPrice,
    required this.currency,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    final specs = json['specs'] as Map<String, dynamic>? ?? {};
    final pricing = json['pricing'] as Map<String, dynamic>? ?? {};
    final listPriceObj = pricing['listPrice'] as Map<String, dynamic>? ?? {};

    return Unit(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      buildingId: json['buildingId'] as String? ?? '',
      floorId: json['floorId'] as String? ?? '',
      status: UnitStatus.fromString(json['status'] as String? ?? 'available'),
      bedrooms: (specs['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (specs['bathrooms'] as num?)?.toInt() ?? 0,
      areaSqm: (specs['areaSqm'] as num?)?.toDouble() ?? 0.0,
      listPrice: (listPriceObj['amount'] as num?)?.toDouble() ?? 0.0,
      currency: listPriceObj['currency'] as String? ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'code': code,
      'projectId': projectId,
      'buildingId': buildingId,
      'floorId': floorId,
      'status': status.name,
      'specs': {
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'areaSqm': areaSqm,
      },
      'pricing': {
        'listPrice': {
          'amount': listPrice,
          'currency': currency,
        },
      },
    };
  }
}
