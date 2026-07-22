enum LeadStage {
  newLead,
  qualified,
  proposal,
  closing,
  won,
  lost;

  static LeadStage fromString(String val) {
    switch (val.toLowerCase()) {
      case 'new':
      case 'newlead':
        return LeadStage.newLead;
      case 'qualified':
        return LeadStage.qualified;
      case 'proposal':
        return LeadStage.proposal;
      case 'closing':
      case 'reservation':
        return LeadStage.closing;
      case 'won':
        return LeadStage.won;
      case 'lost':
        return LeadStage.lost;
      default:
        return LeadStage.newLead;
    }
  }
}

class Lead {
  final String id;
  final String tenantId;
  final String fullName;
  final String email;
  final String phone;
  final LeadStage stage;
  final int aiScore;
  final String ownerUid;

  const Lead({
    required this.id,
    required this.tenantId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.stage,
    required this.aiScore,
    required this.ownerUid,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    final contact = json['contact'] as Map<String, dynamic>? ?? {};
    final pipeline = json['pipeline'] as Map<String, dynamic>? ?? {};
    final ai = json['aiScore'] as Map<String, dynamic>? ?? {};

    return Lead(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      fullName: contact['name'] as String? ?? json['fullName'] as String? ?? '',
      email: contact['email'] as String? ?? json['email'] as String? ?? '',
      phone: contact['phone'] as String? ?? json['phone'] as String? ?? '',
      stage: LeadStage.fromString(pipeline['stage'] as String? ?? 'new'),
      aiScore: (ai['score'] as num?)?.toInt() ?? json['aiScore'] as int? ?? 50,
      ownerUid: json['ownerUid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'contact': {
        'name': fullName,
        'email': email,
        'phone': phone,
      },
      'pipeline': {
        'stage': stage.name,
      },
      'aiScore': {
        'score': aiScore,
      },
      'ownerUid': ownerUid,
    };
  }
}
