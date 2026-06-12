import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'cari_bakiye_rapor_screen.dart';
import 'kritik_stok_rapor_screen.dart';
import 'satis_performans_rapor_screen.dart';
import 'tahsilat_rapor_screen.dart';
import 'stok_ambar_rapor_screen.dart';
import 'stok_durum_rapor_screen.dart';
import 'vade_rapor_screen.dart';
import '../auth/auth_service.dart';

// Raporlar hub ekranı — tüm raporları kategori kartları halinde listeler.
// Hem alt sekme kökü hem de Ana sayfadan push edilerek açılabilir.
class RaporHubScreen extends StatelessWidget {
  const RaporHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final raporlar = <_RaporTanim>[
      // Satış performansı — finansal rapor; yalnızca yetkisi olana göster
      // (backend view_financial_reports ister, Satışçı 403 alır).
      if (authService.perms.canViewFinancialReports)
        _RaporTanim(
          baslik: 'Satış Performansı',
          aciklama: 'Ciro trendi, satışçı performansı ve en çok satış yapılan müşteriler',
          ikon: Icons.trending_up_rounded,
          renk: AppColors.positive,
          ekran: const SatisPerformansRaporScreen(),
        ),
      if (authService.perms.canViewFinancialReports)
        _RaporTanim(
          baslik: 'Tahsilat Raporu',
          aciklama: 'Net tahsilat, nakit/kart kırılımı ve satışçı bazlı tahsilat',
          ikon: Icons.payments_rounded,
          renk: AppColors.accent,
          ekran: const TahsilatRaporScreen(),
        ),
      _RaporTanim(
        baslik: 'Cari Bakiye Raporu',
        aciklama: 'Kod, ünvan, şehir, telefon, borç / alacak / bakiye',
        ikon: Icons.account_balance_wallet_rounded,
        renk: AppColors.accent,
        ekran: const CariBakiyeRaporScreen(),
      ),
      _RaporTanim(
        baslik: 'Vade Raporu',
        aciklama: 'Vadesi geçen cariler ve gecikme yaşlandırması',
        ikon: Icons.event_busy_rounded,
        renk: AppColors.negative,
        ekran: const VadeRaporScreen(),
      ),
      _RaporTanim(
        baslik: 'Stok Durum Raporu',
        aciklama: 'Malzeme ad / açıklama + fiili ve gerçek stok',
        ikon: Icons.inventory_2_rounded,
        renk: AppColors.primary,
        ekran: const StokDurumRaporScreen(),
      ),
      _RaporTanim(
        baslik: 'Ayrıntılı Stok Raporu',
        aciklama: 'Hangi ambarda ne kadar — ambar bazlı döküm',
        ikon: Icons.warehouse_rounded,
        renk: AppColors.accentDark,
        ekran: const StokAmbarRaporScreen(),
      ),
      _RaporTanim(
        baslik: 'Kritik Stok Raporu',
        aciklama: 'Asgari stok seviyesinin altına düşen malzemeler',
        ikon: Icons.warning_amber_rounded,
        renk: AppColors.warning,
        ekran: const KritikStokRaporScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Raporlar'),
        titleTextStyle:
            AppTypography.h1.copyWith(color: AppColors.slate900, fontSize: 22),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: raporlar.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) => _RaporKart(tanim: raporlar[i]),
      ),
    );
  }
}

class _RaporTanim {
  final String baslik;
  final String aciklama;
  final IconData ikon;
  final Color renk;
  final Widget ekran;

  _RaporTanim({
    required this.baslik,
    required this.aciklama,
    required this.ikon,
    required this.renk,
    required this.ekran,
  });
}

class _RaporKart extends StatelessWidget {
  final _RaporTanim tanim;
  const _RaporKart({required this.tanim});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => tanim.ekran),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tanim.renk.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tanim.ikon, color: tanim.renk, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tanim.baslik, style: AppTypography.h3),
                    const SizedBox(height: 2),
                    Text(tanim.aciklama,
                        style: AppTypography.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.slate400),
            ],
          ),
        ),
      ),
    );
  }
}
