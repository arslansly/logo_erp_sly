import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import 'dashboard_model.dart';
import 'dashboard_service.dart';

class BugunTahsilatlarScreen extends StatefulWidget {
  const BugunTahsilatlarScreen({super.key});

  @override
  State<BugunTahsilatlarScreen> createState() =>
      _BugunTahsilatlarScreenState();
}

class _BugunTahsilatlarScreenState extends State<BugunTahsilatlarScreen> {
  late Future<List<SonHareket>> _future;

  @override
  void initState() {
    super.initState();
    _future = dashboardService.getBugunTahsilatlar();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = dashboardService.getBugunTahsilatlar();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Bugün tahsilat',
          style: AppTypography.h1.copyWith(fontSize: 20),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.accent,
        child: FutureBuilder<List<SonHareket>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }
            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString());
            }
            final hareketler = snapshot.data ?? [];
            if (hareketler.isEmpty) {
              return _buildEmpty();
            }
            return _buildContent(hareketler);
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<SonHareket> hareketler) {
    final toplam =
        hareketler.fold<double>(0, (sum, h) => sum + h.netAmount.abs());

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildOzetKart(toplam, hareketler.length),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: List.generate(hareketler.length, (i) {
                  final isLast = i == hareketler.length - 1;
                  return Column(
                    children: [
                      _buildHareketRow(hareketler[i]),
                      if (!isLast)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          child: Container(
                              height: 0.5, color: AppColors.slate200),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOzetKart(double toplam, int adet) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.positive, Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.positive.withValues(alpha: 0.3),
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
              const Icon(Icons.payments_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 6),
              Text(
                'Bugün toplam tahsilat',
                style: AppTypography.caption.copyWith(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Formatters.currency(toplam),
            style: AppTypography.display.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  adet.toString(),
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'fiş',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHareketRow(SonHareket h) {
    final isIn = h.isTahsilat;
    final color = isIn ? AppColors.positive : AppColors.negative;
    final bg = isIn ? AppColors.positiveBg : AppColors.negativeBg;
    final icon =
        isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amount = h.netAmount.abs();
    final sign = isIn ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.cariTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${h.transactionTypeName} · ${Formatters.relativeTime(h.date)}',
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$sign${Formatters.currency(amount)}',
              style: AppTypography.h3.copyWith(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => Container(
        height: i == 0 ? 140 : 64,
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
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: AppColors.slate400,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Tahsilat yok',
                style: AppTypography.h1.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                'Bugün henüz tahsilat fişi girilmemiş.',
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
