import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../cari/cari_detay_screen.dart';
import 'dashboard_service.dart';
import 'vadesi_gecen_cari_model.dart';

class VadesiGecenCarilerScreen extends StatefulWidget {
  const VadesiGecenCarilerScreen({super.key});

  @override
  State<VadesiGecenCarilerScreen> createState() =>
      _VadesiGecenCarilerScreenState();
}

class _VadesiGecenCarilerScreenState extends State<VadesiGecenCarilerScreen> {
  late Future<List<VadesiGecenCari>> _future;

  @override
  void initState() {
    super.initState();
    _future = dashboardService.getVadesiGecenCariler();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = dashboardService.getVadesiGecenCariler();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Vadesi geçen',
          style: AppTypography.h1.copyWith(fontSize: 20),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.accent,
        child: FutureBuilder<List<VadesiGecenCari>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }
            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString());
            }
            final cariler = snapshot.data ?? [];
            if (cariler.isEmpty) {
              return _buildEmpty();
            }
            return _buildContent(cariler);
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<VadesiGecenCari> cariler) {
    final toplamTutar = cariler.fold<double>(0, (sum, c) => sum + c.vadesiGecenTutar);
    final kritikSayi = cariler.where((c) => c.riskLevel == RiskLevel.kritik).length;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Üst özet kart
        SliverToBoxAdapter(
          child: _buildOzetKart(toplamTutar, cariler.length, kritikSayi),
        ),
        // Cari kartları
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final cari = cariler[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildCariCard(cari),
                );
              },
              childCount: cariler.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOzetKart(double toplamTutar, int cariSayisi, int kritikSayi) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.negative, Color(0xFF991B1B)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.negative.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 6),
              Text(
                'Vadesi geçen toplam',
                style: AppTypography.caption.copyWith(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Formatters.currency(toplamTutar),
            style: AppTypography.display.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ozetMetric(
                count: cariSayisi.toString(),
                label: 'Toplam cari',
              ),
              const SizedBox(width: 20),
              if (kritikSayi > 0)
                _ozetMetric(
                  count: kritikSayi.toString(),
                  label: 'Kritik (90+ gün)',
                  highlight: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ozetMetric({
    required String count,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: AppTypography.h2.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCariCard(VadesiGecenCari cari) {
    final colors = _riskColors(cari.riskLevel);
    final riskLabel = _riskLabel(cari.riskLevel);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CariDetayScreen(cariId: cari.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Sol: gün sayısı dairesi
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cari.enEskiGunFarki.toString(),
                      style: AppTypography.h2.copyWith(
                        color: colors.fg,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'gün',
                      style: AppTypography.caption.copyWith(
                        color: colors.fg,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Orta: ünvan + risk etiketi
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
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.bg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            riskLabel,
                            style: AppTypography.caption.copyWith(
                              color: colors.fg,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cari.vadeSayisi > 1
                                ? '${cari.vadeSayisi} vade · ${cari.code}'
                                : cari.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.slate500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Sağ: tutar
              Text(
                Formatters.currency(cari.vadesiGecenTutar),
                style: AppTypography.h3.copyWith(
                  color: AppColors.negative,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Yardımcılar ───
  ({Color bg, Color fg}) _riskColors(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.kritik:
        return (bg: AppColors.negativeBg, fg: const Color(0xFF991B1B));
      case RiskLevel.yuksek:
        return (bg: const Color(0xFFFFE4E6), fg: const Color(0xFFDC2626));
      case RiskLevel.orta:
        return (bg: const Color(0xFFFFEDD5), fg: const Color(0xFFEA580C));
      case RiskLevel.dusuk:
        return (bg: AppColors.warningBg, fg: AppColors.warning);
    }
  }

  String _riskLabel(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.kritik:
        return 'KRİTİK';
      case RiskLevel.yuksek:
        return 'YÜKSEK';
      case RiskLevel.orta:
        return 'ORTA';
      case RiskLevel.dusuk:
        return 'DÜŞÜK';
    }
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => Container(
        height: i == 0 ? 140 : 80,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.slate400),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.slate600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.positiveBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: AppColors.positive,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Harika!',
                style: AppTypography.h1.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                'Vadesi geçmiş bir cariniz yok.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}