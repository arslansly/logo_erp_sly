import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import 'patron_model.dart';
import 'patron_service.dart';

/// Banka hesapları + güncel bakiye listesi (patron paneli drill-down).
class BankaHesaplarScreen extends StatefulWidget {
  const BankaHesaplarScreen({super.key});

  @override
  State<BankaHesaplarScreen> createState() => _BankaHesaplarScreenState();
}

class _BankaHesaplarScreenState extends State<BankaHesaplarScreen> {
  late Future<List<BankaHesap>> _future;

  @override
  void initState() {
    super.initState();
    _future = patronService.getBankaHesaplar();
  }

  Future<void> _refresh() async {
    setState(() => _future = patronService.getBankaHesaplar());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Banka hesapları', style: AppTypography.h1.copyWith(fontSize: 20)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.accent,
        child: FutureBuilder<List<BankaHesap>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _loading();
            }
            if (snap.hasError) return _error(snap.error.toString());
            final hesaplar = snap.data ?? [];
            if (hesaplar.isEmpty) return _empty();
            return _content(hesaplar);
          },
        ),
      ),
    );
  }

  Widget _content(List<BankaHesap> hesaplar) {
    final toplam = hesaplar.fold<double>(0, (s, h) => s + h.bakiye);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _ozetKart(toplam, hesaplar.length),
        const SizedBox(height: 16),
        for (final h in hesaplar) ...[
          _hesapCard(h),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _ozetKart(double toplam, int adet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.violetMid],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Toplam banka bakiyesi',
              style: AppTypography.caption
                  .copyWith(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(Formatters.currency(toplam),
              style: AppTypography.display
                  .copyWith(color: Colors.white, fontSize: 30)),
          const SizedBox(height: 6),
          Text('$adet hesap',
              style: AppTypography.caption
                  .copyWith(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _hesapCard(BankaHesap h) {
    final negatif = h.bakiye < 0;
    final color = negatif ? AppColors.negative : AppColors.positive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(h.kod,
                style: AppTypography.h3.copyWith(
                  fontSize: 13,
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(h.ad,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h3.copyWith(
                  fontSize: 13,
                  color: AppColors.slate900,
                )),
          ),
          const SizedBox(width: 10),
          Text(Formatters.currency(h.bakiye),
              style: AppTypography.h3.copyWith(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }

  Widget _loading() => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => Container(
          height: i == 0 ? 130 : 72,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );

  Widget _error(String e) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.slate400),
              const SizedBox(height: 16),
              Text(e,
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.bodySmall.copyWith(color: AppColors.slate600)),
            ],
          ),
        ),
      );

  Widget _empty() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text('Banka hesabı bulunamadı',
                style: AppTypography.bodySmall.copyWith(color: AppColors.slate500)),
          ),
        ],
      );
}
