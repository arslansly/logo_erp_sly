import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/settings/settings_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tarih biçimlendirme (tr_TR) — hata olursa uygulama yine de açılmalı.
  try {
    await initializeDateFormatting('tr_TR', null);
  } catch (e, s) {
    debugPrint('initializeDateFormatting hatası: $e\n$s');
  }

  // Kayıtlı sunucu adresini Dio'ya uygula (ayarlar ekranından gelir).
  // flutter_secure_storage iOS Keychain'e erişir; ilk açılışta hata
  // fırlatabilir — yakalayıp varsayılan adresle devam ediyoruz.
  try {
    await settingsService.applyServerUrl();
  } catch (e, s) {
    debugPrint('applyServerUrl hatası: $e\n$s');
  }

  // JWT token cache'ini önceden doldur (image widget'ları sync token okur)
  try {
    await apiClient.getToken();
  } catch (e, s) {
    debugPrint('getToken hatası: $e\n$s');
  }

  // Kayıtlı rolü önbelleğe al (yetki kontrolleri senkron okur)
  try {
    await authService.loadRole();
  } catch (e, s) {
    debugPrint('loadRole hatası: $e\n$s');
  }

  // 401 yakalandığında login'e yönlendir
  ApiClient.setOn401Callback(() {
    authService.logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  });

  runApp(const LogoMobilApp());
}

class LogoMobilApp extends StatelessWidget {
  const LogoMobilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logo Mobil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('tr', 'TR'),
      home: const LoginScreen(),  // ← Her zaman login ile başla
    );
  }
}
