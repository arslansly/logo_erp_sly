---
description: >
  Flutter UI geliştirme skill'i. Güzel, animasyonlu, production-grade widget'lar
  yazar. Loading skeleton, empty state, hata durumu, animasyon, responsive layout
  konularında devreye gir. AppColors ve AppTypography'yi her zaman kullan.
  "Daha güzel yap", "tasarım iyileştir", "loading ekle", "animasyon ekle",
  "boş durum", "hata ekranı" gibi taleplerde aktive ol.
---

# Flutter UI Design Skill

Bu skill `logo_mobil` projesine özgü, production-grade Flutter UI üretmek içindir.

## Temel Prensipler

1. **Theme first** — Renk ve tipografi için her zaman `AppColors`, `AppTypography`, `Theme.of(context).colorScheme` kullan. Inline değer yasak.
2. **Her state düşünülmeli** — Her async widget şu 3 durumu handle etmeli: loading, error, data.
3. **const her yerde** — Mümkün olan her widget `const` olmalı.
4. **Separation** — Her özel widget ayrı bir dosya veya private `_Widget` class'ı olmalı.

---

## Loading State → Skeleton Loader

`shimmer` paketi kullanılmadıysa `pubspec.yaml`'a ekle:
```yaml
shimmer: ^3.0.0
```

```dart
// lib/core/widgets/skeleton_loader.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
```

**Cari listesi skeleton örneği:**
```dart
class _CariListSkeleton extends StatelessWidget {
  const _CariListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _CariCardSkeleton(),
    );
  }
}

class _CariCardSkeleton extends StatelessWidget {
  const _CariCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 180, height: 16),
          SizedBox(height: 8),
          SkeletonBox(width: 120, height: 12),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 80, height: 14),
              SkeletonBox(width: 60, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Empty State Widget

```dart
// lib/core/widgets/empty_state.dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String baslik;
  final String? aciklama;
  final String? butonMetni;
  final VoidCallback? onButon;

  const EmptyState({
    super.key,
    required this.icon,
    required this.baslik,
    this.aciklama,
    this.butonMetni,
    this.onButon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.scale(scale: 0.8 + 0.2 * value, child: child),
              ),
              child: Icon(icon, size: 72, color: theme.colorScheme.primary.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text(baslik, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (aciklama != null) ...[
              const SizedBox(height: 8),
              Text(
                aciklama!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (butonMetni != null && onButon != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onButon,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(butonMetni!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## Card Tasarımı

`Card` widget'ı yerine özel container kullan:

```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
```

---

## Async Widget Pattern (setState ile)

```dart
// Mevcut StatefulWidget pattern'i için standart async state:
enum _LoadState { loading, error, loaded }

class _SomeScreenState extends State<SomeScreen> {
  _LoadState _state = _LoadState.loading;
  String? _hata;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _state = _LoadState.loading);
    try {
      final result = await someService.getList();
      if (!mounted) return;
      setState(() { _data = result; _state = _LoadState.loaded; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _hata = e.toString(); _state = _LoadState.error; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _LoadState.loading => const _Skeleton(),
      _LoadState.error => EmptyState(
          icon: Icons.error_outline_rounded,
          baslik: 'Bir hata oluştu',
          aciklama: _hata,
          butonMetni: 'Tekrar Dene',
          onButon: _yukle,
        ),
      _LoadState.loaded => _data.isEmpty
          ? const EmptyState(icon: Icons.inbox_rounded, baslik: 'Kayıt bulunamadı')
          : _List(data: _data),
    };
  }
}
```

---

## Animasyon Kuralları

```dart
// ✅ Tercih et
AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, ...)
AnimatedOpacity(duration: const Duration(milliseconds: 200), ...)
TweenAnimationBuilder(...)

// ✅ Liste item girişi için
SliverAnimatedList(...)

// ❌ Kullanma
setState(() => _isVisible = !_isVisible); // kaba toggle
```

---

## Responsive Layout

```dart
// Sabit pixel yazmak yerine:
LayoutBuilder(
  builder: (context, constraints) {
    final isWide = constraints.maxWidth > 600;
    return isWide ? _WideLayout() : _NarrowLayout();
  },
)
```

---

## Checklist (Her yeni widget için)

- [ ] `const` constructor var mı?
- [ ] Loading state (skeleton) handle edildi mi?
- [ ] Error state (EmptyState ile) handle edildi mi?
- [ ] Empty list durumu handle edildi mi?
- [ ] `mounted` kontrolü yapıldı mı (async işlem sonrası)?
- [ ] Inline renk/font yok mu? (`AppColors`, `AppTypography`)
- [ ] Dark mode çalışıyor mu?
