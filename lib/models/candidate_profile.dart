class CandidateProfile {
  final int? id;
  final int? userId;
  final String name;
  final String? photoUrl;
  final String desiredRole;
  final String area;
  final int experienceYears;
  final String education;
  final String city;
  final String state;
  final String country;
  final double? minimumSalaryExpectation;
  final String preferredModality;
  final String preferredContractType;
  final int completionPercentage;
  final List<String> skills;

  const CandidateProfile({
    this.id,
    this.userId,
    this.name = "",
    this.photoUrl,
    this.desiredRole = "",
    this.area = "",
    this.experienceYears = 0,
    this.education = "",
    this.city = "",
    this.state = "",
    this.country = "Brasil",
    this.minimumSalaryExpectation,
    this.preferredModality = "REMOTE",
    this.preferredContractType = "CLT",
    this.completionPercentage = 0,
    this.skills = const [],
  });

  String get role => desiredRole.isNotEmpty ? desiredRole : "Cargo não informado";
  String get location {
    final loc = "$city, $state".trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '');
    return loc.isNotEmpty ? loc : (country.isNotEmpty ? country : "Localização não informada");
  }

  String? get avatarUrl =>
      (photoUrl != null && photoUrl!.trim().isNotEmpty) ? photoUrl!.trim() : null;

  String get salaryExpectation =>
      (minimumSalaryExpectation != null && minimumSalaryExpectation! > 0)
          ? "R\$ ${minimumSalaryExpectation!.toStringAsFixed(0)}+"
          : "A combinar";

  String get modality {
    if (preferredModality == 'REMOTE') return 'Remoto';
    if (preferredModality == 'HYBRID') return 'Híbrido';
    if (preferredModality == 'ONSITE') return 'Presencial';
    return preferredModality;
  }

  String get contractType => preferredContractType;

  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    List<String> sList = [];
    if (json['skills'] is List) {
      sList = List<String>.from(json['skills'].map((s) => s.toString()));
    } else if (json['skillNames'] is List) {
      sList = List<String>.from(json['skillNames'].map((s) => s.toString()));
    }

    return CandidateProfile(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      desiredRole: json['desiredRole']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      experienceYears: json['experienceYears'] is int
          ? json['experienceYears']
          : int.tryParse(json['experienceYears']?.toString() ?? '') ?? 0,
      education: json['education']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? 'Brasil',
      minimumSalaryExpectation: json['minimumSalaryExpectation'] != null
          ? double.tryParse(json['minimumSalaryExpectation'].toString())
          : null,
      preferredModality: json['preferredModality']?.toString() ?? 'REMOTE',
      preferredContractType: json['preferredContractType']?.toString() ?? 'CLT',
      completionPercentage: json['completionPercentage'] is int
          ? json['completionPercentage']
          : int.tryParse(json['completionPercentage']?.toString() ?? '') ?? 0,
      skills: sList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'desiredRole': desiredRole,
      'area': area,
      'experienceYears': experienceYears,
      'education': education,
      'city': city,
      'state': state,
      'country': country,
      'minimumSalaryExpectation': minimumSalaryExpectation,
      'preferredModality': preferredModality,
      'preferredContractType': preferredContractType,
      'skillNames': skills,
      'skills': skills,
    };
  }
}
