import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'irsaliye_model.dart';

class IrsaliyeService {
  final Dio _dio = apiClient.dio;

  Future<List<IrsaliyeModel>> getIrsaliyeler({
    int offset = 0,
    int limit = 50,
    String? search,
    DateTime? baslangic,
    DateTime? bitis,
    int? trCode,
    bool? faturalandi,
    int? cariId,
  }) async {
    try {
      final params = <String, dynamic>{'offset': offset, 'limit': limit};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (baslangic != null) params['baslangic'] = baslangic.toIso8601String();
      if (bitis != null) params['bitis'] = bitis.toIso8601String();
      if (trCode != null) params['trCode'] = trCode;
      if (faturalandi != null) params['faturalandi'] = faturalandi;
      if (cariId != null) params['cariId'] = cariId;

      final response = await _dio.get('/api/Irsaliye', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => IrsaliyeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<IrsaliyeDetayModel> getDetay(int id) async {
    try {
      final response = await _dio.get('/api/Irsaliye/$id/detay');
      return IrsaliyeDetayModel.fromJson(response.data as Map<String, dynamic>);
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
      return 'İrsaliye bulunamadı';
    }
    return 'İrsaliye hatası: ${e.message}';
  }
}

final irsaliyeService = IrsaliyeService();
