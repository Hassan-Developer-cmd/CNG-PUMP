enum UserRole {
  operator,
  supervisor,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.operator:
        return 'Operator';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get value => name;

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.operator;
    switch (value.toLowerCase().trim()) {
      case 'supervisor':
        return UserRole.supervisor;
      case 'admin':
        return UserRole.admin;
      case 'operator':
      default:
        return UserRole.operator;
    }
  }
}

class CngUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String assignedStation;
  final bool isActive;
  final DateTime createdAt;

  const CngUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = UserRole.operator,
    required this.assignedStation,
    this.isActive = true,
    required this.createdAt,
  });

  factory CngUser.fromJson(Map<String, dynamic> json) {
    return CngUser(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: (json['name'] ?? json['username']) as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRoleExtension.fromString(json['role'] as String?),
      assignedStation: (json['assignedStation'] ?? json['station'] ?? json['stationName']) as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get username => name.isNotEmpty ? name : (email.contains('@') ? email.split('@').first : email);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'assignedStation': assignedStation,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CngUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? assignedStation,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CngUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedStation: assignedStation ?? this.assignedStation,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
