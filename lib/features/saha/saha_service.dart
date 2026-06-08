import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'saha_model.dart';

/// Saha (satışçı) paneli servisi — `/api/saha/*` uçlarını çağırır.
/// Uçlar backend'de "view_saha_panel" yetkisiyle korunur; yetkisiz kullanıcı 403 alır.
class SahaService {
  final Dio _dio = apiClient.dio;

  // Satışçı kırılımı (leaderboard + seçici)
  Future<List<SahaSatisci>> getSatiscilar() async {
    try {
      final res = await _dio.get('/api/Saha/satiscilar');
      return (res.data as List<dynamic>)
          .map((j) => SahaSatisci.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Seçili kapsam özeti — satisciRef null = tümü
  Future<SahaOzet> getOzet({int? satisciRef}) async {
    try {
      final res = await _dio.get(
        '/api/Saha/ozet',
        queryParameters: satisciRef != null ? {'satisciRef': satisciRef} : null,
      );
      return SahaOzet.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Açık (sevk bekleyen) siparişler
  Future<List<SahaAcikSiparis>> getAcikSiparisler(
      {int? satisciRef, int limit = 50}) async {
    try {
      final res = await _dio.get(
        '/api/Saha/acik-siparisler',
        queryParameters: {
          'satisciRef': ?satisciRef,
          'limit': limit,
        },
      );
      return (res.data as List<dynamic>)
          .map((j) => SahaAcikSiparis.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Riskli müşteriler (vadesi geçen alacak)
  Future<List<SahaRiskliCari>> getRiskliCariler(
      {int? satisciRef, int limit = 50}) async {
    try {
      final res = await _dio.get(
        '/api/Saha/riskli-cariler',
        queryParameters: {
          'satisciRef': ?satisciRef,
          'limit': limit,
        },
      );
      return (res.data as List<dynamic>)
          .map((j) => SahaRiskliCari.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'API\'ye bağlanılamadı';
    }
    if (e.response?.statusCode == 403) {
      return 'Bu paneli görme yetkiniz yok';
    }
    return 'Hata: ${e.message}';
  }
}

final sahaService = SahaService();
