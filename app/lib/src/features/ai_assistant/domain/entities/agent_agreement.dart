enum AgreementStatus {
  draft,
  review,
  signed,
  active,
  suspended,
  expired,
  terminated;

  static AgreementStatus fromString(String val) {
    return AgreementStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AgreementStatus.draft,
    );
  }
}

class AgentAgreement {
  final String id;
  final String tenantId;
  final String developerLegalName;
  final AgreementStatus status;
  final List<String> projectIds;
  final int attributionWindowDays;
  final double commissionPct;
  final DateTime? effectiveFrom;

  const AgentAgreement({
    required this.id,
    required this.tenantId,
    required this.developerLegalName,
    required this.status,
    required this.projectIds,
    required this.attributionWindowDays,
    required this.commissionPct,
    this.effectiveFrom,
  });

  factory AgentAgreement.fromJson(Map<String, dynamic> json) {
    return AgentAgreement(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      developerLegalName: json['developerLegalName'] as String? ?? '',
      status: AgreementStatus.fromString(json['status'] as String? ?? 'draft'),
      projectIds: (json['projectIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      attributionWindowDays: json['attributionWindowDays'] as int? ?? 90,
      commissionPct: (json['commissionPct'] as num?)?.toDouble() ?? 2.5,
      effectiveFrom: json['effectiveFrom'] != null ? DateTime.parse(json['effectiveFrom'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'developerLegalName': developerLegalName,
      'status': status.name,
      'projectIds': projectIds,
      'attributionWindowDays': attributionWindowDays,
      'commissionPct': commissionPct,
      'effectiveFrom': effectiveFrom?.toIso8601String(),
    };
  }
}
