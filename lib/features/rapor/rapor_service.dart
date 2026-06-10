import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'rapor_model.dart';

// Raporlar servisi — backend /api/Rapor uç noktalarını çağırır.
// cari_service.dart kalıbı: dinamik queryParameters + Türkçe hata mesajı.
class RaporService {
  final Dio _dio = apiClient.dio;

  // 1) Cari hesap/bakiye raporu
  Future<List<CariBakiyeRapor>> getCariBakiye({
    String? search,
    int? tur,
    String? bakiyeDurumu, // 'borclu' | 'alacakli'
  }) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (tur != null) params['tur'] = tur;
      if (bakiyeDurumu != null) params['bakiyeDurumu'] = bakiyeDurumu;
      final response =
          await _dio.get('/api/Rapor/cari-bakiye', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => CariBakiyeRapor.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 2) Vade raporu
  Future<List<VadeRapor>> getVade({int? minGun}) async {
    try {
      final params = <String, dynamic>{};
      if (minGun != null) params['minGun'] = minGun;
      final response =
          await _dio.get('/api/Rapor/vade', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => VadeRapor.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 3) Stok durum raporu
  Future<List<StokRapor>> getStok({
    String? search,
    int? tur,
    String? stokDurumu, // 'var' | 'yok'
  }) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (tur != null) params['tur'] = tur;
      if (stokDurumu != null) params['stokDurumu'] = stokDurumu;
      final response =
          await _dio.get('/api/Rapor/stok', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => StokRapor.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 4) Ayrıntılı stok raporu (ambar dökümü)
  Future<List<StokAmbarRapor>> getStokAmbar({String? search, int? tur}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (tur != null) params['tur'] = tur;
      final response =
          await _dio.get('/api/Rapor/stok-ambar', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => StokAmbarRapor.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 5) Kritik stok raporu
  Future<List<KritikStokRapor>> getKritikStok({String? search, int? tur}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (tur != null) params['tur'] = tur;
      final response =
          await _dio.get('/api/Rapor/kritik-stok', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => KritikStokRapor.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 6) Satış performans / ciro raporu (tek nesne döner)
  Future<SatisPerformansRapor> getSatisPerformans({
    DateTime? baslangic,
    DateTime? bitis,
    int? satisciRef,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (baslangic != null) {
        params['baslangic'] = baslangic.toIso8601String();
      }
      if (bitis != null) params['bitis'] = bitis.toIso8601String();
      if (satisciRef != null) params['satisciRef'] = satisciRef;
      final response = await _dio.get('/api/Rapor/satis-performans',
          queryParameters: params);
      return SatisPerformansRapor.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'API\'ye bağlanılamadı';
    }
    if (e.response?.statusCode == 404) {
      return 'Bulunamadı';
    }
    // Backend BadRequest → { mesaj: "..." }
    final data = e.response?.data;
    if (data is Map && data['mesaj'] != null) {
      return data['mesaj'].toString();
    }
    return 'Beklenmedik hata: ${e.message}';
  }
}

final raporService = RaporService();
