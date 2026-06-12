import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/animated_count.dart';
import 'rapor_model.dart';
import 'rapor_service.dart';
import 'rapor_widgets.dart';

/// Tahsilat raporu — uygulamadan kesilen tahsilat/ödeme fişleri (CollectionDrafts)
/// üzerinden. Hero = Logo'ya akmış (Transferred) GERÇEK net tahsilat; altında
/// onaylı ama henüz akmamış (öngörü) kartı + beklenen net. Ayrıca tür (nakit/kart)
/// kırılımı ve satışçı leaderboard. Finansal rapor (backend: view_financial_reports).
class TahsilatRaporScreen extends StatefulWidget {
  const TahsilatRaporScreen({super.key});

  @override
  State<TahsilatRaporScreen> createState() => _TahsilatRaporScreenState();
}

enum _Donem { bugun, yediGun, otuzGun, buAy }

extension _DonemX on _Donem {
  String get etiket => switch (this) {
        _Donem.bugun => 'Bugün',
        _Donem.yediGun => '7 Gün',
        _Donem.otuzGun => '30 Gün',
        _Donem.buAy => 'Bu Ay',
      };

  (DateTime bas, DateTime bit) get aralik {
    final now = DateTime.now();
    final bugun = DateTime(now.year, now.month, now.day);
    return switch (this) {
      _Donem.bugun => (bugun, bugun),
      _Donem.yediGun => (bugun.subtract(const Duration(days: 6)), bugun),
      _Donem.otuzGun => (bugun.subtract(const Duration(days: 29)), bugun),
      _Donem.buAy => (DateTime(now.year, now.month, 1), bugun),
    };
  }
}

class _TahsilatRaporScreenState extends State<TahsilatRaporScreen> {
  _Donem _donem = _Donem.otuzGun;
  TahsilatRaporu? _rapor;
  String? _hata;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final (bas, bit) = _donem.aralik;
      final r = await raporService.getTahsilatOzet(baslangic: bas, bitis: bit);
      if (!mounted) return;
      setState(() {
        _rapor = r;
        _hata = null;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  void _donemSec(_Donem d) {
    if (d == _donem) return;
    setState(() => _donem = d);
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tahsilat Raporu'),
        titleTextStyle:
            AppTypography.h1.copyWith(color: AppColors.slate900, fontSize: 22),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _DonemBari(secili: _donem, onSec: _donemSec),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_yukleniyor) return const RaporLoading();
    if (_hata != null) return RaporError(mesaj: _hata!, onRetry: _yukle);
    final r = _rapor!;
    if (r.bos) {
      return const RaporEmpty(
        mesaj: 'Bu dönemde tahsilat fişi yok',
        ikon: Icons.payments_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _yukle,
      color: AppColors.positive,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          FadeSlideIn(child: _buildOzet(r)),
          const SizedBox(height: AppSpacing.lg),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: _buildBolum(
              'Tür Dağılımı',
              'nakit / kredi kartı',
              _TurKirilim(nakit: r.nakitToplam, kart: r.kartToplam),
            ),
          ),
          if (r.satiscilar.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: _buildBolum(
                'Satışçı Tahsilatları',
                '${r.satiscilar.length} kişi · tutara göre',
                _SatisciListesi(veri: r.satiscilar),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Özet KPI ───
  Widget _buildOzet(TahsilatRaporu r) {
    return Column(
      children: [
        // Net tahsilat hero (count-up)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.positive, Color(0xFF15803D)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.positive.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 15),
                  const SizedBox(width: 5),
                  Text('Net Tahsilat · Logo\'ya işlendi',
                      style: AppTypography.caption
                          .copyWith(color: Colors.white70, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedCount(
                  value: r.netAktarilan,
                  formatter: Formatters.currency,
                  style: AppTypography.display.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('${r.aktarilanSayi} fiş Logo\'ya aktarıldı · kesinleşti',
                  style: AppTypography.caption
                      .copyWith(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
        // Onaylı ama Logo'ya akmamış → öngörü (sadece varsa göster)
        if (r.akmamisSayi > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildAkmamisKart(r),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _miniKpi(
                ikon: Icons.south_west_rounded,
                renk: AppColors.positive,
                etiket: 'Toplam tahsilat',
                deger: Formatters.currencyCompact(r.toplamTahsilat),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _miniKpi(
                ikon: Icons.north_east_rounded,
                renk: AppColors.negative,
                etiket: 'Toplam ödeme',
                deger: Formatters.currencyCompact(r.toplamOdeme),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Onaylı ama Logo'ya akmamış (öngörü) kartı ───
  Widget _buildAkmamisKart(TahsilatRaporu r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Onaylı · Logo\'ya akmamış',
                    style: AppTypography.h3
                        .copyWith(fontSize: 13.5, color: AppColors.warning)),
              ),
              Text(Formatters.currency(r.netAkmamis),
                  style: AppTypography.h2
                      .copyWith(fontSize: 17, color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${r.akmamisSayi} fiş onaylandı ama henüz Logo\'ya işlenmedi · aktarılınca nete eklenecek',
            style: AppTypography.caption
                .copyWith(fontSize: 11, color: AppColors.slate600),
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Beklenen net (aktarılınca)',
                  style: AppTypography.caption
                      .copyWith(fontSize: 12, color: AppColors.slate600)),
              Text(Formatters.currency(r.beklenenNet),
                  style: AppTypography.h2
                      .copyWith(fontSize: 16, color: AppColors.slate900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniKpi({
    required IconData ikon,
    required Color renk,
    required String etiket,
    required String deger,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, color: renk, size: 18),
          ),
          const SizedBox(height: 10),
          Text(etiket, style: AppTypography.caption.copyWith(fontSize: 11)),
          const SizedBox(height: 3),
          Text(deger,
              style: AppTypography.h2
                  .copyWith(color: AppColors.slate900, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBolum(String baslik, String altBaslik, Widget icerik) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(baslik, style: AppTypography.h3.copyWith(fontSize: 15)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(altBaslik,
                    style: AppTypography.caption.copyWith(fontSize: 11)),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: icerik,
        ),
      ],
    );
  }
}

// ─── Dönem seçici barı ───
class _DonemBari extends StatelessWidget {
  final _Donem secili;
  final ValueChanged<_Donem> onSec;
  const _DonemBari({required this.secili, required this.onSec});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: _Donem.values.map((d) {
          final aktif = d == secili;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => onSec(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: aktif ? AppColors.positive : AppColors.slate100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    d.etiket,
                    style: AppTypography.caption.copyWith(
                      color: aktif ? Colors.white : AppColors.slate500,
                      fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Tür kırılımı (nakit / kart) ───
class _TurKirilim extends StatelessWidget {
  final double nakit;
  final double kart;
  const _TurKirilim({required this.nakit, required this.kart});

  @override
  Widget build(BuildContext context) {
    final maxv = [nakit, kart].fold<double>(0, (p, c) => c > p ? c : p);
    return Column(
      children: [
        _satir('Nakit Tahsilat', Icons.payments_rounded, nakit,
            maxv > 0 ? nakit / maxv : 0, AppColors.positive),
        const SizedBox(height: 14),
        _satir('Kredi Kartı', Icons.credit_card_rounded, kart,
            maxv > 0 ? kart / maxv : 0, AppColors.accent),
      ],
    );
  }

  Widget _satir(String ad, IconData ikon, double tutar, double oran, Color renk) {
    return Row(
      children: [
        Icon(ikon, size: 18, color: renk),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(ad,
                          style: AppTypography.h3.copyWith(fontSize: 13.5))),
                  Text(Formatters.currency(tutar),
                      style: AppTypography.h3
                          .copyWith(fontSize: 13.5, color: renk)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: oran),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    backgroundColor: AppColors.slate100,
                    valueColor: AlwaysStoppedAnimation(renk),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Satışçı leaderboard ───
class _SatisciListesi extends StatelessWidget {
  final List<TahsilatSatisci> veri;
  const _SatisciListesi({required this.veri});

  @override
  Widget build(BuildContext context) {
    final maxToplam =
        veri.map((e) => e.toplam).fold<double>(0, (p, c) => c > p ? c : p);
    return Column(
      children: List.generate(veri.length, (i) {
        final s = veri[i];
        final oran = maxToplam > 0 ? s.toplam / maxToplam : 0.0;
        return Padding(
          padding: EdgeInsets.only(bottom: i == veri.length - 1 ? 0 : 14),
          child: Row(
            children: [
              _Madalya(sira: i),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.kullanici.isEmpty ? 'Bilinmiyor' : s.kullanici,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h3.copyWith(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(Formatters.currencyCompact(s.toplam),
                            style: AppTypography.h3.copyWith(
                                fontSize: 14, color: AppColors.positive)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: oran),
                        duration: Duration(milliseconds: 500 + i * 60),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          backgroundColor: AppColors.slate100,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.positive),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${s.adet} fiş',
                        style: AppTypography.caption.copyWith(fontSize: 10.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Madalya extends StatelessWidget {
  final int sira;
  const _Madalya({required this.sira});

  @override
  Widget build(BuildContext context) {
    final renkler = [
      const Color(0xFFF59E0B),
      AppColors.slate400,
      const Color(0xFFB45309),
    ];
    final renk = sira < 3 ? renkler[sira] : AppColors.slate300;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text('${sira + 1}',
          style: AppTypography.h3.copyWith(
              fontSize: 13, color: sira < 3 ? renk : AppColors.slate600)),
    );
  }
}
