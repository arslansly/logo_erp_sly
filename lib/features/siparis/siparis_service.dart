import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'siparis_model.dart';

class SiparisService {
  final Dio _dio = apiClient.dio;

  Future<List<SiparisModel>> getSiparisler({
    int offset = 0,
    int limit = 50,
    String? search,
    DateTime? baslangic,
    DateTime? bitis,
    int? trCode,
    int? status,
    int? cariId,
  }) async {
    try {
      final params = <String, dynamic>{'offset': offset, 'limit': limit};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (baslangic != null) params['baslangic'] = baslangic.toIso8601String();
      if (bitis != null) params['bitis'] = bitis.toIso8601String();
      if (trCode != null) params['trCode'] = trCode;
      if (status != null) params['status'] = status;
      if (cariId != null) params['cariId'] = cariId;

      final response = await _dio.get('/api/Siparis', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => SiparisModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<SiparisDetayModel> getDetay(int id) async {
    try {
      final response = await _dio.get('/api/Siparis/$id/detay');
      return SiparisDetayModel.fromJson(response.data as Map<String, dynamic>);
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
      return 'Sipariş bulunamadı';
    }
    return 'Sipariş hatası: ${e.message}';
  }
}

final siparisService = SiparisService();
