import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

// Raporlar alanı için ortak küçük widget'lar (liste durum ekranları + filtre çipi).

// Shimmer benzeri iskelet yükleme listesi
class RaporLoading extends StatelessWidget {
  final double itemHeight;
  const RaporLoading({super.key, this.itemHeight = 76});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => Container(
        height: itemHeight,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// Hata durumu — ikon + mesaj + tekrar dene
class RaporError extends StatelessWidget {
  final String mesaj;
  final VoidCallback onRetry;
  const RaporError({super.key, required this.mesaj, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.negativeBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.negative, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Bağlantı sorunu', style: AppTypography.h2.copyWith(fontSize: 20)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              mesaj,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.slate600),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Boş durum — ikon + mesaj
class RaporEmpty extends StatelessWidget {
  final String mesaj;
  final IconData ikon;
  const RaporEmpty({
    super.key,
    this.mesaj = 'Kayıt bulunamadı',
    this.ikon = Icons.search_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ikon, size: 56, color: AppColors.slate400),
          const SizedBox(height: AppSpacing.md),
          Text(mesaj,
              style: AppTypography.h2.copyWith(color: AppColors.slate600)),
        ],
      ),
    );
  }
}

// Arama kutusu (AppBar bottom'unda)
class RaporSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const RaporSearchBar({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.body
              .copyWith(color: AppColors.slate500, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.slate500, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: AppTypography.body.copyWith(fontSize: 14),
        onChanged: onChanged,
      ),
    );
  }
}

// Filtre çipi (malzeme listesindeki desenle aynı)
class RaporChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? ikon;
  final Color? aktifRenk;

  const RaporChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.ikon,
    this.aktifRenk,
  });

  @override
  Widget build(BuildContext context) {
    final renk = aktifRenk ?? AppColors.accent;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? renk : AppColors.slate100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? renk : AppColors.slate200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ikon != null) ...[
                Icon(ikon,
                    size: 15,
                    color: selected ? Colors.white : AppColors.slate500),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: selected ? Colors.white : AppColors.slate600,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
