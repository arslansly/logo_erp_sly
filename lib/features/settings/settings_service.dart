import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_client.dart';
import 'settings_model.dart';

/// Bağlantı ayarlarını (sunucu adresi + firma/dönem) okur/yazar.
/// Bu anahtarlar `logout()` sırasında SİLİNMEZ — cihazda kalıcıdır.
class SettingsService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const serverUrlKey = 'server_url';
  static const firmaNoKey = 'firma_no';
  static const donemNoKey = 'donem_no';

  // Varsayılanlar — ayar hiç yapılmamışsa kullanılır.
  static const String defaultServerUrl = ApiClient.defaultBaseUrl;
  static const String defaultFirmaNo = '126';
  static const String defaultDonemNo = '01';

  // ─── Kayıtlı ayarları oku (yoksa varsayılana düş) ───
  Future<AppConfig> load() async {
    final url = await _storage.read(key: serverUrlKey);
    final firma = await _storage.read(key: firmaNoKey);
    final donem = await _storage.read(key: donemNoKey);
    return AppConfig(
      serverUrl: (url == null || url.isEmpty) ? defaultServerUrl : url,
      firmaNo: (firma == null || firma.isEmpty) ? defaultFirmaNo : firma,
      donemNo: (donem == null || donem.isEmpty) ? defaultDonemNo : donem,
    );
  }

  // ─── Ayarları kaydet + ApiClient adresini güncelle ───
  Future<void> save(AppConfig config) async {
    await _storage.write(key: serverUrlKey, value: config.serverUrl);
    await _storage.write(key: firmaNoKey, value: config.firmaNo);
    await _storage.write(key: donemNoKey, value: config.donemNo);
    apiClient.updateBaseUrl(config.serverUrl);
  }

  // ─── Başlangıçta kayıtlı adresi Dio'ya uygula ───
  Future<void> applyServerUrl() async {
    final config = await load();
    apiClient.updateBaseUrl(config.serverUrl);
  }

  // ─── Verilen adrese hafif bağlantı testi (/api/health) ───
  // Başarılıysa true; aksi halde Türkçe hata fırlatır.
  Future<bool> testConnection(String url) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    try {
      final response = await dio.get('/api/health');
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw 'Sunucuya ulaşılamadı. Adresi ve ağ bağlantısını kontrol edin.';
      }
      throw 'Bağlantı testi başarısız (${e.response?.statusCode ?? 'bilinmiyor'})';
    } catch (_) {
      throw 'Bağlantı testi başarısız';
    }
  }
}

final settingsService = SettingsService();
