import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // Varsayılan backend adresi — ilk kurulumda ya da ayar yoksa kullanılır.
  // Çalışma anında ayarlardan okunan adres `updateBaseUrl` ile değiştirilir.
  static const String defaultBaseUrl = 'http://192.168.61.94:5249';

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: defaultBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ─── Token Interceptor: her isteğe otomatik JWT ekler ───
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Login endpoint'ine token ekleme (henüz token yok)
          if (!options.path.contains('/Auth/')) {
            final token = await _storage.read(key: 'jwt_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // 401 — ama login endpoint'ini HAKLA (orada 401 normal)
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/Auth/')) {
            _on401Stream?.call();
          }
          handler.next(error);
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        responseBody: false,
        error: true,
      ),
    );
  }

  // JWT token'ı doğrudan okumak için (örn. CachedNetworkImage httpHeaders)
  // İlk okumadan sonra cache'lenir; her image isteğinde storage'a gitmez.
  String? _cachedToken;
  Future<String?> getToken() async {
    _cachedToken ??= await _storage.read(key: 'jwt_token');
    return _cachedToken;
  }
  String? get cachedTokenSync => _cachedToken;
  void clearCachedToken() => _cachedToken = null;

  // Backend adresini çalışma anında değiştirir (ayarlar ekranından).
  void updateBaseUrl(String url) {
    dio.options.baseUrl = url;
  }

  // 401 yakalandığında çağrılacak callback
  static Function? _on401Stream;
  static void setOn401Callback(Function callback) {
    _on401Stream = callback;
  }
}

final apiClient = ApiClient();