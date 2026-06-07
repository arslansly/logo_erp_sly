class LoginRequest {
  final String username;
  final String password;
  // Ayarlardan seçilen firma/dönem — backend JWT claim'ine gömer.
  final String? firmaNo;
  final String? donemNo;

  LoginRequest({
    required this.username,
    required this.password,
    this.firmaNo,
    this.donemNo,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    if (firmaNo != null) 'firmaNo': firmaNo,
    if (donemNo != null) 'donemNo': donemNo,
  };
}

class LoginResponse {
  final String token;
  final DateTime expiresAt;
  final UserInfo user;

  LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserInfo {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  // Effective yetkiler (backend hesaplar: rol varsayılanı + override).
  final List<String> permissions;

  UserInfo({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.permissions = const [],
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}