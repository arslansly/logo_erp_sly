import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'masraf_model.dart';

// Saha gider (masraf) fişi CRUD + fiş fotoğrafı yükleme/gösterme.
// Backend: /api/ExpenseDraft. Oluşturma/güncelleme multipart/form-data ile gider
// (fiş fotoğrafı IFormFile). Onay/Reddet işlemleri ortak onayService üzerinden.
class MasrafService {
  final Dio _dio = apiClient.dio;

  // Fiş fotoğrafının tam URL'i — CachedNetworkImage için (Authorization header'lı).
  String receiptUrl(int id) =>
      '${_dio.options.baseUrl}/api/ExpenseDraft/$id/receipt';

  // Liste — onay/ödeme durumuna göre filtre. Satışçı kendi masraflarını,
  // patron/muhasebe hepsini görür (backend yetkiye göre süzer).
  Future<List<MasrafModel>> getMasraflar({
    String? approvalStatus,
    String? paymentStatus,
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{'offset': offset, 'limit': limit};
      if (approvalStatus != null) params['approvalStatus'] = approvalStatus;
      if (paymentStatus != null) params['paymentStatus'] = paymentStatus;
      final response =
          await _dio.get('/api/ExpenseDraft', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => MasrafModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MasrafModel> getMasraf(int id) async {
    try {
      final response = await _dio.get('/api/ExpenseDraft/$id');
      return MasrafModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Yeni masraf — fiş fotoğrafı (opsiyonel) ile multipart gönderilir.
  Future<MasrafModel> createMasraf(MasrafModel masraf, {File? foto}) async {
    try {
      final form = await _formData(masraf, foto);
      final response = await _dio.post('/api/ExpenseDraft', data: form);
      return MasrafModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Güncelle — yeni fotoğraf verilmezse mevcut fiş korunur.
  Future<MasrafModel> updateMasraf(int id, MasrafModel masraf,
      {File? foto}) async {
    try {
      final form = await _formData(masraf, foto);
      final response = await _dio.put('/api/ExpenseDraft/$id', data: form);
      return MasrafModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMasraf(int id) async {
    try {
      await _dio.delete('/api/ExpenseDraft/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Patron "Ödendi" işaretler — onaylı + henüz ödenmemiş masraf için.
  Future<void> markOdendi(int id, {String? method}) async {
    try {
      await _dio.post('/api/ExpenseDraft/$id/odendi',
          data: {'paymentMethod': method});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Model alanları + (varsa) fiş fotoğrafından multipart FormData kurar.
  Future<FormData> _formData(MasrafModel masraf, File? foto) async {
    final map = <String, dynamic>{...masraf.toFormFields()};
    if (foto != null) {
      final ext = foto.path.split('.').last.toLowerCase();
      final mime = (ext == 'png') ? 'png' : 'jpeg';
      map['receipt'] = await MultipartFile.fromFile(
        foto.path,
        filename: 'fis.$mime',
        contentType: DioMediaType('image', mime),
      );
    }
    return FormData.fromMap(map);
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'API\'ye bağlanılamadı';
    }
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'].toString();
    if (e.response?.statusCode == 404) return 'Masraf bulunamadı';
    if (e.response?.statusCode == 401) return 'Oturum süreniz dolmuş';
    return 'Beklenmedik hata: ${e.message}';
  }
}

final masrafService = MasrafService();
