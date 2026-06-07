import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/app_role.dart';
import '../settings/settings_service.dart';
import 'auth_model.dart';



class AuthService {


  final Dio _dio = apiClient.dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _userKey = 'user_fullname';
  static const _roleKey = 'user_role';
  static const _permsKey = 'user_perms';
  static const _expiryKey = 'token_expiry';

  // ─── Rol + yetki önbelleği (senkron okuma için) ───
  // login()'de doldurulur; ekranlar (MainShell vb.) build içinde senkron okur.
  AppRole? _cachedRole;
  Set<String>? _cachedPerms;

  /// Aktif kullanıcının rolü (senkron). Yüklenmemişse en az yetkili rol.
  AppRole get role => _cachedRole ?? AppRole.satisci;

  /// Aktif kullanıcının effective yetki seti (senkron) — UI gizleme/gösterme için.
  /// Yüklenmemişse boş (deny-all); login her zaman doldurur.
  Permissions get perms => Permissions(_cachedPerms ?? const <String>{});

  /// Depodaki rol + yetkileri önbelleğe yükler (boot'ta). login() zaten doldurur.
  Future<void> loadRole() async {
    final storedRole = await _storage.read(key: _roleKey);
    _cachedRole = AppRole.fromString(storedRole);
    _cachedPerms = _parsePerms(await _storage.read(key: _permsKey));
  }

  Set<String> _parsePerms(String? csv) =>
      (csv == null || csv.isEmpty) ? <String>{} : csv.split(',').toSet();

  // ─── Login ───
  Future<LoginResponse> login(String username, String password) async {
    try {
      // Ayarlardan seçilen firma/dönem'i login isteğine ekle
      final config = await settingsService.load();

      final response = await _dio.post(
        '/api/Auth/login',
        data: LoginRequest(
          username: username,
          password: password,
          firmaNo: config.firmaNo,
          donemNo: config.donemNo,
        ).toJson(),

      );

      final loginResponse = LoginResponse.fromJson(
          response.data as Map<String, dynamic>);

      // Token'ı güvenli depoya kaydet
      await _storage.write(key: 'last_username', value: username);
      await _storage.write(key: _tokenKey, value: loginResponse.token);
      await _storage.write(key: _userKey, value: loginResponse.user.fullName);
      await _storage.write(key: _roleKey, value: loginResponse.user.role);
      await _storage.write(
          key: _expiryKey, value: loginResponse.expiresAt.toIso8601String());

      // Rol + yetki önbelleğini hemen doldur — MainShell senkron okuyacak.
      _cachedRole = AppRole.fromString(loginResponse.user.role);
      _cachedPerms = loginResponse.user.permissions.toSet();
      await _storage.write(
          key: _permsKey, value: loginResponse.user.permissions.join(','));

      // ApiClient token cache'ini güncelle
      apiClient.clearCachedToken();
      await apiClient.getToken();

      return loginResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw 'Kullanıcı adı veya şifre hatalı';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw 'Sunucuya bağlanılamadı. API çalışıyor mu?';
      }
      throw 'Giriş sırasında bir hata oluştu';
    }
  }

  // ─── Kayıtlı token'ı oku ───
  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    // Süresi geçmiş mi kontrol et
    final expiryStr = await _storage.read(key: _expiryKey);
    if (expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().isAfter(expiry)) {
        await logout(); // Süresi dolmuş, temizle
        return null;
      }
    }
    return token;
  }

  Future<String?> getLastUsername() async {
    return await _storage.read(key: 'last_username');
  }

  // ─── Kullanıcı adı oku ───
  Future<String?> getUserName() async {
    return await _storage.read(key: _userKey);
  }

  // ─── Kullanıcı rolü oku (örn. "Admin") ───
  Future<String?> getUserRole() async {
    return await _storage.read(key: _roleKey);
  }

  // ─── Admin mi? ───
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role?.toLowerCase() == 'admin';
  }

  // ─── Çıkış yap — kullanıcı adı + bağlantı ayarlarını koru ───
  Future<void> logout() async {
    // deleteAll her şeyi siler; korunması gereken anahtarları önce okuyup geri yaz.
    final lastUser = await _storage.read(key: 'last_username');
    final serverUrl = await _storage.read(key: SettingsService.serverUrlKey);
    final firmaNo = await _storage.read(key: SettingsService.firmaNoKey);
    final donemNo = await _storage.read(key: SettingsService.donemNoKey);

    await _storage.deleteAll();

    if (lastUser != null) {
      await _storage.write(key: 'last_username', value: lastUser);
    }
    if (serverUrl != null) {
      await _storage.write(key: SettingsService.serverUrlKey, value: serverUrl);
    }
    if (firmaNo != null) {
      await _storage.write(key: SettingsService.firmaNoKey, value: firmaNo);
    }
    if (donemNo != null) {
      await _storage.write(key: SettingsService.donemNoKey, value: donemNo);
    }
    _cachedRole = null;
    _cachedPerms = null;
    apiClient.clearCachedToken();
  }



  // ─── Oturum var mı? ───
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}

final authService = AuthService();