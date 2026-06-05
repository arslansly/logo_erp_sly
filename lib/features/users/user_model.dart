/// AppUsers tablosundaki uygulama kullanıcısı (backend UserListItem ile eşleşir).
/// Şifre hash'i istemciye hiç gelmez.
class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        (v == null) ? null : DateTime.tryParse(v as String);
    return AppUser(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'User',
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: parseDate(json['lastLoginAt']),
      createdAt: parseDate(json['createdAt']),
    );
  }
}
