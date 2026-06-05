import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'fatura_model.dart';

// LOGO faturalarının okuma servisi (backend: /api/Fatura).
// Yazma akışı için FaturaTaslakService kullanılır.
class FaturaService {
  final Dio _dio = apiClient.dio;

  // Liste — sayfalı + filtreli
  Future<List<FaturaModel>> getFaturalar({
    int offset = 0,
    int limit = 50,
    String? search,
    DateTime? baslangic,
    DateTime? bitis,
    int? trCode,
    int? cariId,
    String? kategori, // 'Satış' | 'Satınalma' | 'İade'
  }) async {
    try {
      final params = <String, dynamic>{'offset': offset, 'limit': limit};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (baslangic != null) params['baslangic'] = baslangic.toIso8601String();
      if (bitis != null) params['bitis'] = bitis.toIso8601String();
      if (trCode != null) params['trCode'] = trCode;
      if (cariId != null) params['cariId'] = cariId;
      if (kategori != null) params['kategori'] = kategori;

      final response = await _dio.get('/api/Fatura', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => FaturaModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Header tek başına (nadiren gerekir; genelde detay kullanılır)
  Future<FaturaModel> getFaturaById(int id) async {
    try {
      final response = await _dio.get('/api/Fatura/$id');
      return FaturaModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Detay — header + satırlar + bağlı belgeler tek call
  Future<FaturaDetayModel> getFaturaDetay(int id) async {
    try {
      final response = await _dio.get('/api/Fatura/$id/detay');
      return FaturaDetayModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PDF (TODO: backend PDF endpoint'i devreye girince aktif olacak)
  Future<List<int>> getFaturaPdf(int id) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/Fatura/$id/pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? <int>[];
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
      return 'Fatura bulunamadı';
    }
    if (e.response?.statusCode == 401) {
      return 'Oturum süreniz dolmuş';
    }
    return 'Beklenmedik hata: ${e.message}';
  }
}

final faturaService = FaturaService();
