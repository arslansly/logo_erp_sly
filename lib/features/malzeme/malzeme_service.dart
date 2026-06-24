import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'malzeme_model.dart';

class MalzemeService {
  final Dio _dio = apiClient.dio;

  Future<List<Malzeme>> getMalzemeler({
    int offset = 0,
    int limit = 50,
    String? search,
    String? stokDurumu, // null=hepsi, 'var'=stoğu olanlar, 'yok'=stoğu olmayanlar
    int? tur, // CARDTYPE: 10=Hammadde, 11=Yarı Mamul, 12=Mamul, 1=Ticari Mal...
  }) async {
    try {
      final params = <String, dynamic>{'offset': offset, 'limit': limit};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (stokDurumu != null) params['stokDurumu'] = stokDurumu;
      if (tur != null) params['tur'] = tur;
      final response = await _dio.get('/api/Malzeme', queryParameters: params);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => Malzeme.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MalzemeDetay> getMalzemeDetay(int id) async {
    try {
      final response = await _dio.get('/api/Malzeme/$id');
      return MalzemeDetay.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MalzemeHareket>> getHareketler(
    int id, {
    DateTime? baslangic,
    DateTime? bitis,
    bool? giris,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (baslangic != null) {
        params['baslangic'] = baslangic.toIso8601String();
      }
      if (bitis != null) {
        params['bitis'] = bitis.toIso8601String();
      }
      if (giris != null) {
        params['giris'] = giris;
      }
      final response = await _dio.get(
        '/api/Malzeme/$id/hareketler',
        queryParameters: params,
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) => MalzemeHareket.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Barkod numarasına göre malzeme arar; bulunamazsa null döner.
  Future<Malzeme?> getMalzemeByBarkod(String barkod) async {
    try {
      final response = await _dio.get('/api/Malzeme/barkod/$barkod');
      return Malzeme.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    }
  }

  // Malzeme kart resminin tam URL'i — CachedNetworkImage için kullanılır.
  String resimUrl(int id) => '${_dio.options.baseUrl}/api/Malzeme/$id/resim';

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'API\'ye bağlanılamadı';
    }
    if (e.response?.statusCode == 404) {
      return 'Malzeme bulunamadı';
    }
    return 'Beklenmedik hata: ${e.message}';
  }
}

final malzemeService = MalzemeService();
