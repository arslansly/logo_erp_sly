import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import 'patron_model.dart';
import 'patron_service.dart';

/// Bir bankanın hesapları (patron paneli drill-down 2. seviye).
/// Her hesap: ad + döviz rozeti + IBAN + güncel bakiye (BNFLINE'dan).
class BankaHesapDetayScreen extends StatefulWidget {
  final int bankaRef;
  final String bankaAd;

  const BankaHesapDetayScreen({
    super.key,
    required this.bankaRef,
    required this.bankaAd,
  });

  @override
  State<BankaHesapDetayScreen> createState() => _BankaHesapDetayScreenState();
}

class _BankaHesapDetayScreenState extends State<BankaHesapDetayScreen> {
  late Future<List<BankaHesap>> _future;

  @override
  void initState() {
    super.initState();
    _future = patronService.getBankaHesaplar(widget.bankaRef);
  }

  Future<void> _refresh() async {
    setState(() => _future = patronService.getBankaHesaplar(widget.bankaRef));
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Banka hesapları',
                style: AppTypography.h2.copyWith(fontSize: 16)),
            Text(widget.bankaAd,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(fontSize: 11)),
          ],
        ),
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
    final negatif = toplam < 0;
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
          Text('Banka toplamı',
              style: AppTypography.caption
                  .copyWith(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Formatters.currency(toplam),
                maxLines: 1,
                style: AppTypography.display.copyWith(
                  color: negatif ? AppColors.pinkLight : Colors.white,
                  fontSize: 30,
                )),
          ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(h.ad,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h3.copyWith(
                            fontSize: 13,
                            color: AppColors.slate900,
                          )),
                    ),
                    if (h.currencyKod.isNotEmpty && h.currencyKod != 'TL') ...[
                      const SizedBox(width: 6),
                      _dovizRozet(h.currencyKod),
                    ],
                  ],
                ),
                if (h.iban.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(h.iban,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(fontSize: 10.5)),
                ],
              ],
            ),
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

  Widget _dovizRozet(String kod) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(kod,
            style: AppTypography.caption.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.accentDark,
            )),
      );

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
            child: Text('Bu bankada hesap yok',
                style: AppTypography.bodySmall.copyWith(color: AppColors.slate500)),
          ),
        ],
      );
}
