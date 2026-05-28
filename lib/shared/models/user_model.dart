class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String role;
  final bool isActive;
  final String? avatarUrl;
  final bool onboardingDone;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.role,
    required this.isActive,
    this.avatarUrl,
    required this.onboardingDone,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      avatarUrl: json['avatar_url'] as String?,
      onboardingDone: json['onboarding_done'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'role': role,
    'is_active': isActive,
    'avatar_url': avatarUrl,
    'onboarding_done': onboardingDone,
    'created_at': createdAt.toIso8601String(),
  };

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isSalesman => role == 'salesman';
  bool get isAdminOrManager => isAdmin || isManager;

  String get roleDisplayName {
    switch (role) {
      case 'admin': return 'Admin';
      case 'manager': return 'Manager';
      case 'salesman': return 'Salesman';
      default: return role;
    }
  }

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
  }
}
