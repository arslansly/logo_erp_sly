---
description: >
  Riverpod state management skill'i. Yeni feature için provider yaz,
  mevcut StatefulWidget + setState kodunu Riverpod'a migrate et.
  "Riverpod ekle", "provider yaz", "state management kur",
  "setState'i temizle", "global state" gibi taleplerde aktive ol.
  logo_mobil projesine özgü: Dio + JWT auth + feature-first mimari.
---

# Flutter Riverpod Skill

`logo_mobil` projesine Riverpod entegrasyonu için rehber.

## Kurulum

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1   # isteğe bağlı — code gen için

dev_dependencies:
  riverpod_generator: ^2.6.1    # isteğe bağlı
  build_runner: ^2.4.0          # isteğe bağlı
```

`main.dart`'ı wrap et:
```dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## Provider Tipleri — Ne Zaman Hangisi

| Durum | Provider |
|---|---|
| API'den async veri çek | `AsyncNotifierProvider` |
| Lokal / form state | `NotifierProvider` |
| Sadece okuma (service singleton) | `Provider` |
| Basit bool/int toggle | `StateProvider` (geçici, sonra NotifierProvider'a geç) |

---

## Standart Async Provider Pattern

Bu proje için standart async veri provider'ı:

```dart
// lib/features/cari/cari_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cari_model.dart';
import 'cari_service.dart';

// Service'i provider olarak expose et (singleton korunur)
final cariServiceProvider = Provider<CariService>((ref) => cariService);

// Async veri provider'ı
final cariListeProvider = AsyncNotifierProvider<CariListeNotifier, List<CariModel>>(
  CariListeNotifier.new,
);

class CariListeNotifier extends AsyncNotifier<List<CariModel>> {
  @override
  Future<List<CariModel>> build() async {
    return _yukle();
  }

  Future<List<CariModel>> _yukle() async {
    final service = ref.read(cariServiceProvider);
    return service.getCariListesi(); // Türkçe hata fırlatır, doğrudan propagate et
  }

  Future<void> yenile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_yukle);
  }
}
```

---

## UI'da Kullanım

```dart
// StatefulWidget yerine ConsumerWidget kullan
class CariListeScreen extends ConsumerWidget {
  const CariListeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cariListesi = ref.watch(cariListeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Listesi')),
      body: cariListesi.when(
        loading: () => const _CariListSkeleton(),
        error: (hata, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          baslik: 'Hata oluştu',
          aciklama: hata.toString(),
          butonMetni: 'Tekrar Dene',
          onButon: () => ref.refresh(cariListeProvider),
        ),
        data: (liste) => liste.isEmpty
            ? const EmptyState(
                icon: Icons.people_outline_rounded,
                baslik: 'Cari bulunamadı',
              )
            : _CariListesi(liste: liste),
      ),
    );
  }
}
```

---

## StatefulWidget → Riverpod Migrate Adımları

Mevcut `StatefulWidget` + `setState` kodu varsa şu adımları izle:

1. **State'i belirle** — `setState` ile güncellenen tüm field'ları listele.
2. **Provider seç** — API çağrısı varsa `AsyncNotifierProvider`, değilse `NotifierProvider`.
3. **Widget'ı değiştir** — `StatefulWidget` → `ConsumerWidget` (veya `ConsumerStatefulWidget` animasyon gibi lifecycle lazımsa).
4. **initState kaldır** — `build()` metodu provider'da initial fetch yapar.
5. **setState kaldır** — UI `ref.watch` ile reaktif olur.
6. **mounted kontrollerini kaldır** — Provider tarafında gerek yok.

---

## Auth State (Mevcut Sisteme Dokunma)

Mevcut `flutter_secure_storage` + `authService` singleton iyi çalışıyor. Auth'u şimdilik Riverpod'a migrate etme. Sadece `authStateProvider` ekleyebilirsin:

```dart
// lib/features/auth/auth_provider.dart
final authStateProvider = StateProvider<bool>((ref) => false);

// main.dart'taki 401 callback güncellenir:
// ref.read(authStateProvider.notifier).state = false;
```

---

## Klasör Yapısı Kuralı

Provider dosyaları feature klasörünün içinde:
```
lib/features/cari/
  cari_model.dart
  cari_service.dart
  cari_provider.dart   ← YENİ
  cari_screen.dart
```

---

## Sık Hatalar

```dart
// ❌ ref.read ile UI'da okuma (reaktif değil)
final liste = ref.read(cariListeProvider);

// ✅ ref.watch ile UI'da okuma
final liste = ref.watch(cariListeProvider);

// ✅ Action'larda (buton onPressed vs.) ref.read kullan
onPressed: () => ref.read(cariListeProvider.notifier).yenile(),

// ❌ ConsumerWidget dışında ref kullanma
// ✅ Lazımsa ConsumerStatefulWidget kullan
```
