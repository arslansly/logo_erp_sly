import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'dashboard_model.dart';
import 'vadesi_gecen_cari_model.dart';

class DashboardService {
  final Dio _dio = apiClient.dio;

  Future<DashboardOzet> getOzet() async {
    try {
      final response = await _dio.get('/api/Dashboard/ozet');
      return DashboardOzet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<SonHareket>> getSonHareketler({int limit = 5}) async {
    try {
      final response = await _dio.get(
        '/api/Dashboard/son-hareketler',
        queryParameters: {'limit': limit},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => SonHareket.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  Future<List<SonHareket>> getBugunTahsilatlar() async {
    try {
      final response = await _dio.get('/api/Dashboard/bugun-tahsilatlar');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => SonHareket.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<VadesiGecenCari>> getVadesiGecenCariler() async {
    try {
      final response = await _dio.get('/api/Dashboard/vadesi-gecen-cariler');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => VadesiGecenCari.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'API\'ye bağlanılamadı';
    }
    return 'Hata: ${e.message}';
  }
}

final dashboardService = DashboardService();