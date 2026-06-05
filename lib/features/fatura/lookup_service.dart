import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'currency_model.dart';

// Form dropdown'ları için lookup service.
class LookupService {
  final Dio _dio = apiClient.dio;

  // Tüm dövizleri getir (TL hariç, mobil tarafta listenin başına eklenir)
  Future<List<CurrencyModel>> getCurrencies() async {
    try {
      final response = await _dio.get('/api/Lookup/currencies');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => CurrencyModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Satış elemanları
  Future<List<LookupItem>> getSalesmen() => _getList('/api/Lookup/salesmen');

  // Ödeme planları
  Future<List<LookupItem>> getPayPlans() => _getList('/api/Lookup/payplans');

  // Ambarlar (L_CAPIWHOUSE) — id = ambar numarası (STFICHE.SOURCEINDEX/DESTINDEX)
  Future<List<LookupItem>> getWarehouses() => _getList('/api/Lookup/warehouses');

  // Taşıyıcılar (L_SHPAGENT) — code = STFICHE'ye yazılacak taşıyıcı kodu
  Future<List<LookupItem>> getCarriers() => _getList('/api/Lookup/carriers');

  Future<List<LookupItem>> _getList(String path) async {
    try {
      final response = await _dio.get(path);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => LookupItem.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Verilen döviz için en güncel kuru getir.
  // hasData=false dönerse mobil kur field'ını boş bırakır, kullanıcı manuel girer.
  Future<ExchangeRateModel> getExchangeRate(int currencyType) async {
    try {
      final response = await _dio.get(
        '/api/Lookup/exchange-rate',
        queryParameters: {'currencyType': currencyType},
      );
      return ExchangeRateModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'API\'ye bağlanılamadı';
    }
    return 'Lookup hatası: ${e.message}';
  }
}

final lookupService = LookupService();
