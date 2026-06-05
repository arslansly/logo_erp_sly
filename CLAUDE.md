# CLAUDE.md

Bu dosya Claude Code'a (`claude.ai/code`) bu repoda çalışırken rehberlik eder.

---

## Overview

`logo_mobil` is a Flutter mobile client for a Logo ERP backend (a Turkish accounting/ERP system). It surfaces dashboard summaries and customer-account ("cari") data from a REST API. All code comments, UI strings, and user-facing error messages are in **Turkish**.

---

## Commands

```sh
flutter pub get                 # bağımlılıkları kur
flutter run                     # cihaz/emülatörde çalıştır
flutter analyze                 # statik analiz / lint (flutter_lints)
flutter test                    # tüm testleri çalıştır
flutter test path/to/file.dart  # tekil test dosyası
flutter build apk               # release Android build
```

Requires Dart SDK `^3.11.5`.

---

## Architecture

### Klasör Yapısı
```
lib/
  core/
    api/          # ApiClient (Dio singleton)
    theme/        # AppColors, AppTypography, AppTheme
    utils/
  features/
    auth/         # *_model.dart | *_service.dart | *_screen.dart
    dashboard/
    cari/
    shell/
    welcome/
```

**Kural:** Yeni feature eklenirken mutlaka bu üçlü yapıya (`model`, `service`, `screen`) uy. Cross-cutting kod `lib/core/` altına gider.

### Networking
- `ApiClient` singleton → `lib/core/api/api_client.dart`
- Dio request interceptor: her istekte `Bearer` JWT otomatik eklenir (`flutter_secure_storage`'dan okunur), `/Auth/` path'leri hariç.
- 401 error interceptor → `authService.logout()` + `LoginScreen` yönlendirme (`navigatorKey` ile).
- ⚠️ Backend URL `api_client.dart` içinde hardcode'lu LAN IP (`http://192.168.61.98:5249`) — ortama göre değiştirilmeli.

### Services
- Her feature: `authService`, `cariService`, `dashboardService` — `apiClient.dio`'yu paylaşır.
- `DioException` yakalanır, Türkçe kullanıcı mesajına dönüştürülür (`_handleError` private metodu).
- Caller `catch` edip mesajı direkt gösterir — typed exception kullanılmaz.

### Auth Flow
- Login: `jwt_token`, `user_fullname`, `token_expiry`, `last_username` → `flutter_secure_storage`
- `logout()` → her şeyi siler, `last_username` korunur.
- Boot → her zaman `LoginScreen`. Başarılı login → `MainShell` (bottom-nav, `IndexedStack`).

---

## State Management

**Mevcut durum:** `StatefulWidget` + `setState`. Screen'ler service singleton'larını direkt çağırır (`initState` / Future içinde).

**Yeni kod yazarken:** Önce `setState` ile başla. Eğer state birden fazla widget arasında paylaşılıyorsa veya async loading/error/data pattern'i gerekiyorsa `Riverpod` kullan:
- `AsyncNotifierProvider` → async veri (API calls)
- `NotifierProvider` → senkron/lokal state
- `ref.watch` → UI'da okuma, `ref.read` → action'larda

Mevcut `StatefulWidget` kodunu refactor etme — sadece yeni feature'lar için Riverpod öner.

---

## Theme & UI Standartları

**Tema:** `lib/core/theme/` — `AppColors`, `AppTypography`, `AppTheme`.  
Material 3 + Google Fonts (Inter).

### Kurallar (kesinlikle uy)
- Inline renk yazma → `AppColors.*` kullan
- Inline TextStyle yazma → `AppTypography.*` kullan
- `Theme.of(context).colorScheme.*` → doğrudan `AppColors` yerine bu tercih edilir
- `MediaQuery.of(context).size` ile responsive layout → `LayoutBuilder` tercih edilir
- Dark mode: her yeni widget dark mode'u desteklemeli (`Theme.of(context).brightness`)

### UI Kalite Kuralları
- Loading state: `CircularProgressIndicator` yerine `Shimmer` skeleton loader kullan
- Error state: her async widget'ın boş/hata durumu göstermeli (empty state widget)
- Animasyon: `AnimatedContainer`, `AnimatedOpacity`, `TweenAnimationBuilder` tercih et — kaba `setState` ile toggle yapma
- `Card` yerine özel `Container` + `BoxDecoration` ile daha iyi shadow/border radius kullan
- `ListTile` yerine özel tile widget'ı — daha fazla kontrol için
- `Padding` yerine mümkünse `SizedBox` + layout widget'ları

### Spacing & Layout
```dart
// Sabit spacing değerleri — inline sayı yazma
// Bunları lib/core/theme/app_spacing.dart olarak ekle:
static const double xs = 4.0;
static const double sm = 8.0;
static const double md = 16.0;
static const double lg = 24.0;
static const double xl = 32.0;
```

---

## Domain Glossary (Türkçe Terimler)

| Terim | Anlam |
|---|---|
| cari | hesap / müşteri veya tedarikçi |
| hareket | işlem / hesap hareketi |
| vade | vade tarihi; **vadesi geçen** = vadesi dolmuş |
| fatura | fatura |
| özet (ozet) | özet |
| borçlu / alacaklı | borçlu / alacaklı (bakiye işareti) |

---

## Kod Yazım Kuralları

- Tüm UI string'leri, hata mesajları, yorum satırları **Türkçe**
- Her servis metodunun üstünde kısa bir Türkçe yorum olmalı
- `print()` kullanma → `debugPrint()` kullan
- `BuildContext` async gap'lerden sonra `mounted` kontrolü yap
- `const` constructor'ları her yerde kullan (lint uyarılarına dikkat et)
- Magic number kullanma → named constant tanımla

---

## Skill'ler

Bu proje için `.claude/skills/` altında iki aktif skill var:

- **flutter-ui-design** → Güzel UI, animasyon, skeleton loader, empty state yazımı
- **flutter-riverpod** → Mevcut `setState` kodunu Riverpod'a migrate etme ve yeni provider yazma
