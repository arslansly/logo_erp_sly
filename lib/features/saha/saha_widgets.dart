import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import 'saha_model.dart';

/// Saha paneli ve drill-down ekranlarında paylaşılan satır/durum widget'ları.

/// İnce ayraç (liste satırları arası).
class SahaDivider extends StatelessWidget {
  const SahaDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(height: 0.5, color: AppColors.slate200),
      );
}

/// Boş durum kutusu (yumuşak, bilgilendirici).
class SahaEmptyState extends StatelessWidget {
  final IconData icon;
  final String mesaj;
  const SahaEmptyState({super.key, required this.icon, required this.mesaj});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.positive),
          const SizedBox(height: 10),
          Text(mesaj,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.slate500)),
        ],
      ),
    );
  }
}

/// Açık (sevk bekleyen) sipariş satırı.
class AcikSiparisTile extends StatelessWidget {
  final SahaAcikSiparis siparis;
  final bool showSatisci; // "Tümü" görünümünde satışçı adını göster
  final VoidCallback onTap;

  const AcikSiparisTile({
    super.key,
    required this.siparis,
    required this.onTap,
    this.showSatisci = false,
  });

  @override
  Widget build(BuildContext context) {
    final bayat = siparis.bayat;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: AppColors.accentDark, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(siparis.cariAd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      siparis.ficheNo,
                      Formatters.relativeTime(siparis.tarih),
                      if (showSatisci && siparis.satisciAd.isNotEmpty)
                        siparis.satisciAd,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatters.currencyCompact(siparis.bekleyenTutar),
                    style: AppTypography.h3.copyWith(
                      fontSize: 14,
                      color: AppColors.slate900,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: bayat ? AppColors.warningBg : AppColors.slate100,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${siparis.gunGecti} gün',
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: bayat ? AppColors.warning : AppColors.slate500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Riskli müşteri satırı (vadesi geçen alacak).
class RiskliCariTile extends StatelessWidget {
  final SahaRiskliCari cari;
  final VoidCallback onTap;

  const RiskliCariTile({super.key, required this.cari, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.negativeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.negative, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cari.cariAd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      '${cari.enEskiGun} gün geride',
                      if (cari.acikSiparis > 0)
                        'açık ${Formatters.currencyCompact(cari.acikSiparis)}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatters.currencyCompact(cari.vadesiGecen),
                    style: AppTypography.h3.copyWith(
                      fontSize: 14,
                      color: AppColors.negative,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 1),
                Text('vadesi geçen',
                    style:
                        AppTypography.caption.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
