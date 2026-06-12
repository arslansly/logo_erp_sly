import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'tahsilat_model.dart';

// Taslak tahsilat/ödeme fişi CRUD + LOGO'ya aktarım (backend: /api/CollectionDraft).
// Aktarım şimdilik stub — toplu aktarım ileride REST ile devreye alınacak.
class TahsilatTaslakService {
  final Dio _dio = apiClient.dio;

  // Liste — status='Draft' | 'Failed' | 'Transferred' veya null=hepsi
  Future<List<TahsilatTaslakModel>> getTaslaklar({
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
          await _dio.get('/api/CollectionDraft', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => TahsilatTaslakModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TahsilatTaslakModel> getTaslakById(int id) async {
    try {
      final response = await _dio.get('/api/CollectionDraft/$id');
      return TahsilatTaslakModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TahsilatTaslakModel> createTaslak(TahsilatTaslakModel draft) async {
    try {
      final response =
          await _dio.post('/api/CollectionDraft', data: draft.toJson());
      return TahsilatTaslakModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TahsilatTaslakModel> updateTaslak(
      int id, TahsilatTaslakModel draft) async {
    try {
      final response =
          await _dio.put('/api/CollectionDraft/$id', data: draft.toJson());
      return TahsilatTaslakModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTaslak(int id) async {
    try {
      await _dio.delete('/api/CollectionDraft/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Zorunlu/opsiyonel ek alanları Logo'dan öğrenir. Backend henüz şema endpoint'i
  // sunmuyorsa baseline (ek alan yok) döner — form yine de standart alanlarla çalışır.
  Future<TahsilatSema> getSchema(int trCode) async {
    try {
      final response = await _dio.get('/api/CollectionDraft/schema',
          queryParameters: {'trCode': trCode});
      return TahsilatSema.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      // Şema endpoint'i yok/stub: standart alanlarla devam et.
      return TahsilatSema.baseline();
    }
  }

  // LOGO'ya aktarım — başarılıysa CLFICHE.LOGICALREF döner, aksi halde hata.
  // Backend şu an stub — her zaman "henüz aktif değil" hatası döner, taslak Failed olur.
  Future<int> transferTaslak(int id) async {
    try {
      final response = await _dio.post('/api/CollectionDraft/$id/transfer');
      final data = response.data as Map<String, dynamic>;
      return data['ficheId'] as int;
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
          await _dio.post('/api/CollectionDraft/transfer-batch', data: ids);
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
    if (e.response?.statusCode == 404) return 'Tahsilat fişi bulunamadı';
    if (e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) return data['error'].toString();
      return 'Geçersiz istek';
    }
    if (e.response?.statusCode == 401) return 'Oturum süreniz dolmuş';
    return 'Beklenmedik hata: ${e.message}';
  }
}

final tahsilatTaslakService = TahsilatTaslakService();
