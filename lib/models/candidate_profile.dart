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
    this.name = "Ana Silva",
    this.photoUrl,
    this.desiredRole = "Desenvolvedora Frontend Pleno",
    this.area = "Tecnologia",
    this.experienceYears = 3,
    this.education = "Ensino Superior Completo",
    this.city = "São Paulo",
    this.state = "SP",
    this.country = "Brasil",
    this.minimumSalaryExpectation = 6000.0,
    this.preferredModality = "REMOTE",
    this.preferredContractType = "CLT / PJ",
    this.completionPercentage = 85,
    this.skills = const ["React", "TypeScript", "Tailwind CSS", "Git"],
  });

  String get role => desiredRole;
  String get location => "$city, $state".trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '');
  String get avatarUrl => (photoUrl != null && photoUrl!.isNotEmpty)
      ? photoUrl!
      : "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop";
  String get salaryExpectation => minimumSalaryExpectation != null
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
    }

    return CandidateProfile(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? ''),
      name: json['name']?.toString() ?? 'Candidato',
      photoUrl: json['photoUrl']?.toString(),
      desiredRole: json['desiredRole']?.toString() ?? 'Profissional',
      area: json['area']?.toString() ?? 'Tecnologia',
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
          : int.tryParse(json['completionPercentage']?.toString() ?? '') ?? 70,
      skills: sList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'photoUrl': photoUrl,
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
      'skills': skills,
    };
  }
}
