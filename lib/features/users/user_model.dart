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

/// Bir kullanıcının tek bir yetki satırı (admin yetki editörü).
/// default = rol varsayılanı, overrideValue = kişiye özel istisna (null = yok),
/// effective = sonuç (override ?? default).
class PermissionItem {
  final String key;
  final bool defaultGranted;
  final bool? overrideValue;
  final bool effective;

  PermissionItem({
    required this.key,
    required this.defaultGranted,
    required this.overrideValue,
    required this.effective,
  });

  factory PermissionItem.fromJson(Map<String, dynamic> json) {
    return PermissionItem(
      key: json['key'] as String? ?? '',
      defaultGranted: json['default'] as bool? ?? false,
      overrideValue: json['override'] as bool?,
      effective: json['effective'] as bool? ?? false,
    );
  }
}

/// Kullanıcının yetki tablosu (rol + satırlar).
class UserPermissions {
  final String role;
  final List<PermissionItem> items;

  UserPermissions({required this.role, required this.items});

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      role: json['role'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PermissionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
