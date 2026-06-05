/// Uygulama bağlantı ayarları: backend adresi + LOGO firma/dönem numarası.
/// Giriş ekranındaki ayarlardan düzenlenir, `flutter_secure_storage`'a yazılır.
class AppConfig {
  final String serverUrl;
  final String firmaNo;
  final String donemNo;

  const AppConfig({
    required this.serverUrl,
    required this.firmaNo,
    required this.donemNo,
  });

  AppConfig copyWith({
    String? serverUrl,
    String? firmaNo,
    String? donemNo,
  }) {
    return AppConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      firmaNo: firmaNo ?? this.firmaNo,
      donemNo: donemNo ?? this.donemNo,
    );
  }
}
