enum UserRole {
  candidate,
  company,
}

class AuthUser {
  final int id;
  final String email;
  final UserRole role;
  final String? companyRole;
  final int? companyId;

  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    this.companyRole,
    this.companyId,
  });

  bool get isCandidate => role == UserRole.candidate;
  bool get isCompany => role == UserRole.company;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] ?? 'CANDIDATE').toString().toUpperCase();
    return AuthUser(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      role: roleStr == 'COMPANY' ? UserRole.company : UserRole.candidate,
      companyRole: json['companyRole'],
      companyId: json['companyId'] != null ? (json['companyId'] is int ? json['companyId'] : int.tryParse(json['companyId'].toString())) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': isCandidate ? 'CANDIDATE' : 'COMPANY',
      'companyRole': companyRole,
      'companyId': companyId,
    };
  }
}
