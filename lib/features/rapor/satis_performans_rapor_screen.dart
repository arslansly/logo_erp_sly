import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/animated_count.dart';
import '../cari/cari_detay_screen.dart';
import 'rapor_model.dart';
import 'rapor_service.dart';
import 'rapor_widgets.dart';

/// Satış performans / ciro raporu — özet KPI + aylık ciro trendi (animasyonlu
/// bar grafik) + satışçı performans leaderboard + en çok satış yapılan müşteriler.
/// Patron/Muhasebe/Admin için finansal rapor (backend: view_financial_reports).
class SatisPerformansRaporScreen extends StatefulWidget {
  const SatisPerformansRaporScreen({super.key});

  @override
  State<SatisPerformansRaporScreen> createState() =>
      _SatisPerformansRaporScreenState();
}

class _SatisPerformansRaporScreenState
    extends State<SatisPerformansRaporScreen> {
  SatisPerformansRapor? _rapor;
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
      final r = await raporService.getSatisPerformans();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Satış Performansı'),
        titleTextStyle:
            AppTypography.h1.copyWith(color: AppColors.slate900, fontSize: 22),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
        mesaj: 'Bu dönemde satış kaydı yok',
        ikon: Icons.bar_chart_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _yukle,
      color: AppColors.accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          FadeSlideIn(child: _buildOzetKartlar(r)),
          const SizedBox(height: AppSpacing.lg),
          if (r.aylikTrend.isNotEmpty)
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _buildBolum(
                'Aylık Ciro',
                'KDV hariç net satış',
                _AylikCiroChart(veri: r.aylikTrend),
              ),
            ),
          if (r.satiscilar.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: _buildBolum(
                'Satışçı Performansı',
                '${r.satiscilar.length} satışçı · ciroya göre',
                _SatisciListesi(veri: r.satiscilar),
              ),
            ),
          ],
          if (r.topMusteriler.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: _buildBolum(
                'En Çok Satış — Müşteriler',
                'İlk ${r.topMusteriler.length}',
                _MusteriListesi(veri: r.topMusteriler),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Özet KPI kartları ───
  Widget _buildOzetKartlar(SatisPerformansRapor r) {
    return Column(
      children: [
        // Toplam ciro — büyük hero kart (count-up)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.violetMid],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Toplam Ciro (KDV hariç)',
                  style: AppTypography.caption
                      .copyWith(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedCount(
                  value: r.toplamCiro,
                  formatter: Formatters.currency,
                  style: AppTypography.display.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _miniKpi(
                ikon: Icons.receipt_long_rounded,
                renk: AppColors.accent,
                etiket: 'Fatura sayısı',
                deger: '${r.faturaSayisi}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _miniKpi(
                ikon: Icons.calculate_rounded,
                renk: AppColors.positive,
                etiket: 'Ortalama fatura',
                deger: Formatters.currencyCompact(r.ortalamaFatura),
              ),
            ),
          ],
        ),
      ],
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

  // ─── Başlıklı bölüm sarıcı ───
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

// ═══════════════ Aylık ciro bar grafiği (özel, animasyonlu) ═══════════════

class _AylikCiroChart extends StatefulWidget {
  final List<AylikCiro> veri;
  const _AylikCiroChart({required this.veri});

  @override
  State<_AylikCiroChart> createState() => _AylikCiroChartState();
}

class _AylikCiroChartState extends State<_AylikCiroChart> {
  late int _secili; // varsayılan: son ay (en güncel)

  @override
  void initState() {
    super.initState();
    _secili = widget.veri.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final maxCiro = widget.veri
        .map((e) => e.ciro)
        .fold<double>(0, (p, c) => c > p ? c : p);
    final seciliAy = widget.veri[_secili];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seçili ayın özeti (grafiğin üstünde)
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.currency(seciliAy.ciro),
              style: AppTypography.h2
                  .copyWith(color: AppColors.slate900, fontSize: 20),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${seciliAy.etiket} · ${seciliAy.adet} fatura',
                style: AppTypography.caption.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Çubuklar
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.veri.length, (i) {
              final ay = widget.veri[i];
              final oran = maxCiro > 0 ? ay.ciro / maxCiro : 0.0;
              final secili = i == _secili;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _secili = i),
                  child: _Cubuk(
                    oran: oran,
                    etiket: ay.ayKisa,
                    secili: secili,
                    sira: i,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _Cubuk extends StatelessWidget {
  final double oran; // 0..1
  final String etiket;
  final bool secili;
  final int sira;

  const _Cubuk({
    required this.oran,
    required this.etiket,
    required this.secili,
    required this.sira,
  });

  @override
  Widget build(BuildContext context) {
    const maxYukseklik = 118.0;
    final renk = secili ? AppColors.primary : AppColors.accent;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Çubuk 0'dan hedef yüksekliğe doğru büyür (kademeli dalga).
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: oran),
          duration: Duration(milliseconds: 500 + sira * 45),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Container(
            height: (maxYukseklik * v).clamp(3.0, maxYukseklik),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [renk, renk.withValues(alpha: 0.55)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          etiket,
          style: AppTypography.caption.copyWith(
            fontSize: 9.5,
            color: secili ? AppColors.primary : AppColors.slate500,
            fontWeight: secili ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ═══════════════ Satışçı leaderboard ═══════════════

class _SatisciListesi extends StatelessWidget {
  final List<SatisciPerformans> veri;
  const _SatisciListesi({required this.veri});

  @override
  Widget build(BuildContext context) {
    final maxCiro = veri.map((e) => e.ciro).fold<double>(0, (p, c) => c > p ? c : p);
    return Column(
      children: List.generate(veri.length, (i) {
        final s = veri[i];
        final oran = maxCiro > 0 ? s.ciro / maxCiro : 0.0;
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
                          child: Text(s.ad,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.h3.copyWith(fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                        Text(Formatters.currencyCompact(s.ciro),
                            style: AppTypography.h3.copyWith(
                                fontSize: 14, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Ciro oranı barı (animasyonlu dolar)
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
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${s.adet} fatura',
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
  final int sira; // 0 tabanlı
  const _Madalya({required this.sira});

  @override
  Widget build(BuildContext context) {
    final renkler = [
      const Color(0xFFF59E0B), // altın
      AppColors.slate400, // gümüş
      const Color(0xFFB45309), // bronz
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
              fontSize: 13,
              color: sira < 3 ? renk : AppColors.slate600)),
    );
  }
}

// ═══════════════ Top müşteriler ═══════════════

class _MusteriListesi extends StatelessWidget {
  final List<MusteriCiro> veri;
  const _MusteriListesi({required this.veri});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(veri.length, (i) {
        final m = veri[i];
        final sonMu = i == veri.length - 1;
        return Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CariDetayScreen(cariId: m.cariId),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      alignment: Alignment.center,
                      child: Text('${i + 1}',
                          style: AppTypography.caption.copyWith(
                              fontSize: 12, color: AppColors.slate500)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.ad,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.h3.copyWith(fontSize: 13.5)),
                          const SizedBox(height: 1),
                          Text('${m.adet} fatura',
                              style:
                                  AppTypography.caption.copyWith(fontSize: 10.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(Formatters.currencyCompact(m.ciro),
                        style: AppTypography.h3.copyWith(
                            fontSize: 14, color: AppColors.positive)),
                  ],
                ),
              ),
            ),
            if (!sonMu)
              Container(height: 0.5, color: AppColors.slate200),
          ],
        );
      }),
    );
  }
}
