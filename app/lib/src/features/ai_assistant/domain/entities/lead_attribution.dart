enum AttributionStatus {
  pending,
  accepted,
  rejected,
  reassigned,
  frozen,
  disputed;

  static AttributionStatus fromString(String val) {
    return AttributionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AttributionStatus.pending,
    );
  }
}

class LeadAttribution {
  final String id;
  final String tenantId;
  final String agreementId;
  final String leadId;
  final String channel;
  final AttributionStatus status;
  final DateTime capturedAt;

  const LeadAttribution({
    required this.id,
    required this.tenantId,
    required this.agreementId,
    required this.leadId,
    required this.channel,
    required this.status,
    required this.capturedAt,
  });

  factory LeadAttribution.fromJson(Map<String, dynamic> json) {
    return LeadAttribution(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      agreementId: json['agreementId'] as String? ?? '',
      leadId: json['leadId'] as String? ?? '',
      channel: json['channel'] as String? ?? 'web',
      status: AttributionStatus.fromString(json['status'] as String? ?? 'pending'),
      capturedAt: DateTime.parse(json['capturedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'agreementId': agreementId,
      'leadId': leadId,
      'channel': channel,
      'status': status.name,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }
}
