class CompanyProfile {
  final int id;
  final String name;
  final String cnpj;
  final String? description;
  final String? industry;
  final String? companySize;
  final String? website;
  final String? logoUrl;
  final String? city;
  final String? state;
  final String? country;
  final String verificationStatus;
  final String planType;
  final int activeJobsCount;
  final bool active;

  const CompanyProfile({
    required this.id,
    required this.name,
    required this.cnpj,
    this.description,
    this.industry,
    this.companySize,
    this.website,
    this.logoUrl,
    this.city,
    this.state,
    this.country,
    this.verificationStatus = 'UNVERIFIED',
    this.planType = 'FREE',
    this.activeJobsCount = 0,
    this.active = true,
  });

  String get location => "$city, $state".trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '');
  String get displayLogo => (logoUrl != null && logoUrl!.isNotEmpty)
      ? logoUrl!
      : "https://images.unsplash.com/photo-1549923746-c502d488b3ea?w=100&h=100&fit=crop&auto=format";

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Empresa',
      cnpj: json['cnpj']?.toString() ?? '',
      description: json['description']?.toString(),
      industry: json['industry']?.toString(),
      companySize: json['companySize']?.toString(),
      website: json['website']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString() ?? 'Brasil',
      verificationStatus: json['verificationStatus']?.toString() ?? 'UNVERIFIED',
      planType: json['planType']?.toString() ?? 'FREE',
      activeJobsCount: json['activeJobsCount'] is int
          ? json['activeJobsCount']
          : int.tryParse(json['activeJobsCount']?.toString() ?? '') ?? 0,
      active: json['active'] == true,
    );
  }
}
