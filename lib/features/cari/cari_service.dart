import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'cari_model.dart';
import 'cari_hareket_model.dart';
import 'cari_vade_model.dart';
import 'cari_ekstre_model.dart';

class CariService {
  final Dio _dio = apiClient.dio;

  Future<List<Cari>> getCariler({
    int offset = 0,
    int limit = 50,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{'offset': offset, 'limit': limit};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final response = await _dio.get('/api/Cari', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => Cari.fromJson(json as Map<String, dynamic>))
          .where((cari) => !_isBosKayit(cari))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Logo'nun sistemsel boş cari kaydı (CLCARD.LOGICALREF=1, CODE='ÿ' / 0xFF)
  // gerçek bir cari değildir; listede gösterilmez.
  bool _isBosKayit(Cari cari) =>
      cari.id == 1 || cari.code.trim() == 'ÿ';

  Future<Cari> getCariById(int id) async {
    try {
      final response = await _dio.get('/api/Cari/$id');
      return Cari.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<CariHareket>> getHareketler(int cariId) async {
    try {
      final response = await _dio.get('/api/Cari/$cariId/hareketler');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => CariHareket.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CariVadeAnalizi> getVadeAnalizi(int cariId) async {
    try {
      final response = await _dio.get('/api/Cari/$cariId/vade-analizi');
      return CariVadeAnalizi.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CariEkstre> getEkstre(
    int cariId, {
    DateTime? baslangic,
    DateTime? bitis,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (baslangic != null) params['baslangic'] = baslangic.toIso8601String();
      if (bitis != null) params['bitis'] = bitis.toIso8601String();
      final response = await _dio.get(
        '/api/Cari/$cariId/ekstre',
        queryParameters: params,
      );
      return CariEkstre.fromJson(response.data as Map<String, dynamic>);
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
    return 'Beklenmedik hata: ${e.message}';
  }
}

final cariService = CariService();