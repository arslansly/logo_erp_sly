import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'onay_model.dart';

// Onay iş akışı servisi — backend /api/Onay uç noktaları.
// cari_service kalıbı: dinamik queryParameters + Türkçe hata mesajı.
class OnayService {
  final Dio _dio = apiClient.dio;

  // Onay bekleyen taslaklar (opsiyonel tür filtresi)
  Future<List<OnayBekleyen>> getBekleyenler({OnayBelgeTip? tip}) async {
    try {
      final params = <String, dynamic>{};
      if (tip != null) params['tip'] = tip.api;
      final response =
          await _dio.get('/api/Onay/bekleyenler', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => OnayBekleyen.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Onay bekleyen sayıları (Patron paneli rozeti)
  Future<OnayOzet> getOzet() async {
    try {
      final response = await _dio.get('/api/Onay/ozet');
      return OnayOzet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Onayla
  Future<void> onayla(OnayBelgeTip tip, int id) async {
    try {
      await _dio.post('/api/Onay/${tip.api}/$id/onayla');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reddet (opsiyonel gerekçe)
  Future<void> reddet(OnayBelgeTip tip, int id, {String? gerekce}) async {
    try {
      await _dio.post('/api/Onay/${tip.api}/$id/reddet',
          data: {'reason': gerekce});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'API\'ye bağlanılamadı';
    }
    final data = e.response?.data;
    if (data is Map && data['mesaj'] != null) {
      return data['mesaj'].toString();
    }
    return 'Beklenmedik hata: ${e.message}';
  }
}

final onayService = OnayService();
