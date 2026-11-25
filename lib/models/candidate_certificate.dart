class ForensicCheckItem {
  final String code;
  final String severity;
  final bool passed;
  final int points;
  final String detail;

  const ForensicCheckItem({
    required this.code,
    required this.severity,
    required this.passed,
    required this.points,
    required this.detail,
  });

  factory ForensicCheckItem.fromJson(Map<String, dynamic> json) {
    return ForensicCheckItem(
      code: json['code']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'INFO',
      passed: json['passed'] == true,
      points: json['points'] is int
          ? json['points']
          : int.tryParse(json['points']?.toString() ?? '') ?? 0,
      detail: json['detail']?.toString() ?? '',
    );
  }
}

class CandidateCertificate {
  final int id;
  final String courseTitle;
  final String institutionName;
  final int institutionTier;
  final List<String> verifiedSkills;
  final int? workloadHours;
  final int priorityBonus;
  final int trustScore;
  final String? credentialCode;
  final String verificationSummary;
  final String? createdAt;

  const CandidateCertificate({
    required this.id,
    required this.courseTitle,
    required this.institutionName,
    required this.institutionTier,
    this.verifiedSkills = const [],
    this.workloadHours,
    this.priorityBonus = 0,
    this.trustScore = 0,
    this.credentialCode,
    this.verificationSummary = '',
    this.createdAt,
  });

  factory CandidateCertificate.fromJson(Map<String, dynamic> json) {
    final skillsRaw = json['verifiedSkills'];
    final skills = skillsRaw is List
        ? skillsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return CandidateCertificate(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      courseTitle: json['courseTitle']?.toString() ?? 'Certificado verificado',
      institutionName:
          json['institutionName']?.toString() ?? 'Instituição reconhecida',
      institutionTier: json['institutionTier'] is int
          ? json['institutionTier']
          : int.tryParse(json['institutionTier']?.toString() ?? '') ?? 3,
      verifiedSkills: skills,
      workloadHours: json['workloadHours'] is int
          ? json['workloadHours']
          : int.tryParse(json['workloadHours']?.toString() ?? ''),
      priorityBonus: json['priorityBonus'] is int
          ? json['priorityBonus']
          : int.tryParse(json['priorityBonus']?.toString() ?? '') ?? 0,
      trustScore: json['trustScore'] is int
          ? json['trustScore']
          : int.tryParse(json['trustScore']?.toString() ?? '') ?? 0,
      credentialCode: json['credentialCode']?.toString(),
      verificationSummary: json['verificationSummary']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class CertificateValidationResult {
  final bool accepted;
  final String status;
  final int? certificateId;
  final String? courseTitle;
  final String? institutionName;
  final int? institutionTier;
  final List<String> verifiedSkills;
  final int? workloadHours;
  final int priorityBonus;
  final int trustScore;
  final int fraudRiskScore;
  final String? credentialCode;
  final List<String> rejectionReasons;
  final List<ForensicCheckItem> forensicChecks;
  final List<String> whatWasChecked;
  final String summary;

  const CertificateValidationResult({
    required this.accepted,
    required this.status,
    this.certificateId,
    this.courseTitle,
    this.institutionName,
    this.institutionTier,
    this.verifiedSkills = const [],
    this.workloadHours,
    this.priorityBonus = 0,
    this.trustScore = 0,
    this.fraudRiskScore = 0,
    this.credentialCode,
    this.rejectionReasons = const [],
    this.forensicChecks = const [],
    this.whatWasChecked = const [],
    this.summary = '',
  });

  factory CertificateValidationResult.fromJson(Map<String, dynamic> json) {
    final checksRaw = json['forensicChecks'];
    final checks = checksRaw is List
        ? checksRaw
            .whereType<Map<String, dynamic>>()
            .map(ForensicCheckItem.fromJson)
            .toList()
        : <ForensicCheckItem>[];

    return CertificateValidationResult(
      accepted: json['accepted'] == true,
      status: json['status']?.toString() ?? 'REJECTED',
      certificateId: json['certificateId'] is int
          ? json['certificateId']
          : int.tryParse(json['certificateId']?.toString() ?? ''),
      courseTitle: json['courseTitle']?.toString(),
      institutionName: json['institutionName']?.toString(),
      institutionTier: json['institutionTier'] is int
          ? json['institutionTier']
          : int.tryParse(json['institutionTier']?.toString() ?? ''),
      verifiedSkills: json['verifiedSkills'] is List
          ? (json['verifiedSkills'] as List).map((e) => e.toString()).toList()
          : const [],
      workloadHours: json['workloadHours'] is int
          ? json['workloadHours']
          : int.tryParse(json['workloadHours']?.toString() ?? ''),
      priorityBonus: json['priorityBonus'] is int
          ? json['priorityBonus']
          : int.tryParse(json['priorityBonus']?.toString() ?? '') ?? 0,
      trustScore: json['trustScore'] is int
          ? json['trustScore']
          : int.tryParse(json['trustScore']?.toString() ?? '') ?? 0,
      fraudRiskScore: json['fraudRiskScore'] is int
          ? json['fraudRiskScore']
          : int.tryParse(json['fraudRiskScore']?.toString() ?? '') ?? 0,
      credentialCode: json['credentialCode']?.toString(),
      rejectionReasons: json['rejectionReasons'] is List
          ? (json['rejectionReasons'] as List).map((e) => e.toString()).toList()
          : const [],
      forensicChecks: checks,
      whatWasChecked: json['whatWasChecked'] is List
          ? (json['whatWasChecked'] as List).map((e) => e.toString()).toList()
          : const [],
      summary: json['summary']?.toString() ?? '',
    );
  }
}
