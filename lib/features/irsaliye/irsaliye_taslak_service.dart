import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'irsaliye_model.dart';

// Taslak irsaliye CRUD + LOGO'ya aktarım (backend: /api/IrsaliyeDraft).
class IrsaliyeTaslakService {
  final Dio _dio = apiClient.dio;

  // Liste — status='Draft' | 'Failed' | 'Transferred' veya null=hepsi
  Future<List<IrsaliyeModel>> getTaslaklar({
    String? status,
    int offset = 0,
    int limit = 50,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{'offset': offset, 'limit': limit};
      if (status != null) params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final response =
          await _dio.get('/api/IrsaliyeDraft', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => IrsaliyeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<IrsaliyeTaslakModel> getTaslakById(int id) async {
    try {
      final response = await _dio.get('/api/IrsaliyeDraft/$id');
      return IrsaliyeTaslakModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<IrsaliyeTaslakModel> createTaslak(IrsaliyeTaslakModel draft) async {
    try {
      final response =
          await _dio.post('/api/IrsaliyeDraft', data: draft.toJson());
      return IrsaliyeTaslakModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<IrsaliyeTaslakModel> updateTaslak(
      int id, IrsaliyeTaslakModel draft) async {
    try {
      final response =
          await _dio.put('/api/IrsaliyeDraft/$id', data: draft.toJson());
      return IrsaliyeTaslakModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTaslak(int id) async {
    try {
      await _dio.delete('/api/IrsaliyeDraft/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // LOGO'ya aktarım — başarılıysa LOGO STFICHE.LOGICALREF döner, aksi halde hata.
  // Backend şu an stub — her zaman "henüz aktif değil" hatası döner ve taslak Failed olur.
  Future<int> transferTaslak(int id) async {
    try {
      final response = await _dio.post('/api/IrsaliyeDraft/$id/transfer');
      final data = response.data as Map<String, dynamic>;
      return data['shipmentId'] as int;
    } on DioException catch (e) {
      // 409: aktarım reddedildi (stub veya gerçek hata)
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          throw data['error'].toString();
        }
      }
      throw _handleError(e);
    }
  }

  // Toplu aktarım
  Future<Map<String, dynamic>> transferBatch(List<int> ids) async {
    try {
      final response =
          await _dio.post('/api/IrsaliyeDraft/transfer-batch', data: ids);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'API\'ye bağlanılamadı';
    }
    if (e.response?.statusCode == 404) return 'Taslak bulunamadı';
    if (e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) return data['error'].toString();
      return 'Geçersiz istek';
    }
    if (e.response?.statusCode == 401) return 'Oturum süreniz dolmuş';
    return 'Beklenmedik hata: ${e.message}';
  }
}

final irsaliyeTaslakService = IrsaliyeTaslakService();
