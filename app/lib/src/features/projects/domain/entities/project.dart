class Project {
  final String id;
  final String tenantId;
  final String code;
  final String name;
  final String type;
  final String stage;
  final String city;
  final double physicalProgressPct;
  final double financialProgressPct;
  final double spi;
  final double cpi;
  final int totalUnits;
  final int soldUnits;

  const Project({
    required this.id,
    required this.tenantId,
    required this.code,
    required this.name,
    required this.type,
    required this.stage,
    required this.city,
    required this.physicalProgressPct,
    required this.financialProgressPct,
    required this.spi,
    required this.cpi,
    required this.totalUnits,
    required this.soldUnits,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>? ?? {};
    final counts = json['counts'] as Map<String, dynamic>? ?? {};
    final location = json['location'] as Map<String, dynamic>? ?? {};

    return Project(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'mixedUse',
      stage: json['stage'] as String? ?? 'construction',
      city: location['city'] as String? ?? 'Addis Ababa',
      physicalProgressPct: (progress['physicalPct'] as num?)?.toDouble() ?? 0.0,
      financialProgressPct: (progress['financialPct'] as num?)?.toDouble() ?? 0.0,
      spi: (progress['spi'] as num?)?.toDouble() ?? 1.0,
      cpi: (progress['cpi'] as num?)?.toDouble() ?? 1.0,
      totalUnits: (counts['units'] as num?)?.toInt() ?? 0,
      soldUnits: (counts['unitsSold'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'code': code,
      'name': name,
      'type': type,
      'stage': stage,
      'location': {'city': city},
      'progress': {
        'physicalPct': physicalProgressPct,
        'financialPct': financialProgressPct,
        'spi': spi,
        'cpi': cpi,
      },
      'counts': {
        'units': totalUnits,
        'unitsSold': soldUnits,
      },
    };
  }
}
