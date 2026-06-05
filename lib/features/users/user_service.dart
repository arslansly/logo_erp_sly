import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'user_model.dart';

/// Kullanıcı yönetimi servisi (yalnızca Admin). Backend `/api/users`
/// uçlarını çağırır; hatalar Türkçe mesaja dönüştürülür.
class UserService {
  final Dio _dio = apiClient.dio;

  // ─── Tüm kullanıcıları listele ───
  Future<List<AppUser>> getUsers() async {
    try {
      final response = await _dio.get('/api/users');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => AppUser.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Yeni kullanıcı oluştur ───
  Future<void> createUser({
    required String username,
    required String password,
    required String fullName,
    String email = '',
    String role = 'User',
  }) async {
    try {
      await _dio.post('/api/users', data: {
        'username': username,
        'password': password,
        'fullName': fullName,
        'email': email,
        'role': role,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Kullanıcıyı güncelle (password boşsa değişmez) ───
  Future<void> updateUser({
    required int id,
    required String fullName,
    String email = '',
    String role = 'User',
    bool isActive = true,
    String? password,
  }) async {
    try {
      await _dio.put('/api/users/$id', data: {
        'fullName': fullName,
        'email': email,
        'role': role,
        'isActive': isActive,
        if (password != null && password.isNotEmpty) 'password': password,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Kullanıcıyı sil ───
  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete('/api/users/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    // Backend { message } döndürür — varsa onu göster
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Sunucuya bağlanılamadı';
    }
    if (e.response?.statusCode == 403) {
      return 'Bu işlem için yetkiniz yok';
    }
    return 'Beklenmedik hata: ${e.message}';
  }
}

final userService = UserService();
