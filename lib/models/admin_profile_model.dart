class AdminProfile {
  final String name;
  final String username;
  final String email;
  final String? avatarUrl;
  final bool notificationsEnabled;

  const AdminProfile({
    this.name = '',
    this.username = '',
    this.email = '',
    this.avatarUrl,
    this.notificationsEnabled = true,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      name: json['name'] as String? ?? json['username'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  AdminProfile copyWith({
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
    bool? notificationsEnabled,
  }) {
    return AdminProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
