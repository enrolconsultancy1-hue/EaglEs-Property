enum CommissionState {
  notEligible,
  pendingValidation,
  accrued,
  developerApproved,
  scheduled,
  paid,
  rejected,
  disputed,
  reversed,
  cancelled;

  static CommissionState fromString(String val) {
    return CommissionState.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => CommissionState.pendingValidation,
    );
  }
}

class CommissionRecord {
  final String id;
  final String tenantId;
  final String agreementId;
  final String leadId;
  final String unitId;
  final double saleAmount;
  final double commissionAmount;
  final String currency;
  final CommissionState state;

  const CommissionRecord({
    required this.id,
    required this.tenantId,
    required this.agreementId,
    required this.leadId,
    required this.unitId,
    required this.saleAmount,
    required this.commissionAmount,
    required this.currency,
    required this.state,
  });

  factory CommissionRecord.fromJson(Map<String, dynamic> json) {
    return CommissionRecord(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      agreementId: json['agreementId'] as String? ?? '',
      leadId: json['leadId'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      saleAmount: (json['saleAmount'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      state: CommissionState.fromString(json['state'] as String? ?? 'pendingValidation'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'agreementId': agreementId,
      'leadId': leadId,
      'unitId': unitId,
      'saleAmount': saleAmount,
      'commissionAmount': commissionAmount,
      'currency': currency,
      'state': state.name,
    };
  }
}
