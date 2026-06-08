import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'patron_model.dart';

/// Patron paneli servisi — `/api/patron/*` uçlarını çağırır.
/// Uçlar backend'de "view_patron_panel" yetkisiyle korunur; yetkisiz kullanıcı
/// 403 alır (zaten sekme de gizli gelir).
class PatronService {
  final Dio _dio = apiClient.dio;

  // Patron paneli özeti (tek çağrı)
  Future<PatronOzet> getOzet() async {
    try {
      final response = await _dio.get('/api/Patron/ozet');
      return PatronOzet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Bankalar (drill-down 1. seviye): banka + hesap sayısı + toplam bakiye
  Future<List<BankaKayit>> getBankalar() async {
    try {
      final response = await _dio.get('/api/Patron/bankalar');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => BankaKayit.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Bir bankanın hesapları (drill-down 2. seviye): hesap + döviz + bakiye
  Future<List<BankaHesap>> getBankaHesaplar(int bankaRef) async {
    try {
      final response = await _dio.get(
        '/api/Patron/banka-hesaplar',
        queryParameters: {'bankaRef': bankaRef},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => BankaHesap.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Çek/senet listesi — tip: "tahsil" (müşteri) | "odeme" (kendi)
  Future<List<CekKayit>> getCekler(String tip) async {
    try {
      final response = await _dio.get(
        '/api/Patron/cekler',
        queryParameters: {'tip': tip},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => CekKayit.fromJson(j as Map<String, dynamic>))
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

final patronService = PatronService();
