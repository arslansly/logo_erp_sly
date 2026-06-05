import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'cari_model.dart';

class CariCard extends StatelessWidget {
  final Cari cari;
  final VoidCallback? onTap;

  const CariCard({
    super.key,
    required this.cari,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );

    // Bakiyeye göre renk seç
    final isPositive = cari.balance > 0;
    final isNegative = cari.balance < 0;
    final balanceColor = isPositive
        ? AppColors.negative // Müşteri borçlu → kırmızı (bize alacak)
        : isNegative
        ? AppColors.positive // Biz borçluyuz → yeşil
        : AppColors.slate500;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sol: avatar (kod + şehir gözüksün) + e-Fatura/e-Arşiv rozeti
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.9),
                            AppColors.violet.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(cari.title),
                          style: AppTypography.h3.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (cari.eFatura || cari.eArsiv)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: cari.eFatura
                                ? AppColors.positive
                                : AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: AppColors.surface, width: 1.5),
                          ),
                          child: Text(
                            cari.eFatura ? 'EF' : 'EA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Orta: ünvan ve kod + şehir
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cari.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.slate900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cari.city.isEmpty
                          ? cari.code
                          : '${cari.code} · ${cari.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.slate500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Sağ: bakiye (renkli)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(cari.balance.abs()),
                    style: AppTypography.h3.copyWith(
                      color: balanceColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPositive ? 'Alacak' : isNegative ? 'Borç' : 'Sıfır',
                    style: AppTypography.caption.copyWith(
                      color: balanceColor.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "ABC Tekstil Ltd." → "AT"
  String _getInitials(String title) {
    if (title.isEmpty) return '?';
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1))
        .toUpperCase();
  }
}