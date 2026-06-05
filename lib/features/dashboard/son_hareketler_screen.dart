import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import 'dashboard_model.dart';
import 'dashboard_service.dart';

/// Son hareketlerin tam listesi — dashboard'daki "Tümü" butonundan açılır.
class SonHareketlerScreen extends StatefulWidget {
  const SonHareketlerScreen({super.key});

  @override
  State<SonHareketlerScreen> createState() => _SonHareketlerScreenState();
}

class _SonHareketlerScreenState extends State<SonHareketlerScreen> {
  List<SonHareket>? _hareketler;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final list = await dashboardService.getSonHareketler(limit: 100);
      if (!mounted) return;
      setState(() {
        _hareketler = list;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Son Hareketler'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppTypography.h2,
        foregroundColor: AppColors.slate900,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 10,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
    if (_error != null && (_hareketler == null || _hareketler!.isEmpty)) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.slate300),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(_error!,
                style: AppTypography.body.copyWith(color: AppColors.slate600),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
            ),
          ),
        ],
      );
    }
    final list = _hareketler ?? [];
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.slate300),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text('Henüz hareket yok',
                style: AppTypography.body.copyWith(color: AppColors.slate500)),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: SonHareketRow(hareket: list[i]),
      ),
    );
  }
}

/// Tek bir son hareket satırı — dashboard ve liste ekranında paylaşılır.
class SonHareketRow extends StatelessWidget {
  final SonHareket hareket;
  const SonHareketRow({super.key, required this.hareket});

  @override
  Widget build(BuildContext context) {
    final isIn = hareket.isTahsilat;
    final color = isIn ? AppColors.positive : AppColors.negative;
    final bg = isIn ? AppColors.positiveBg : AppColors.negativeBg;
    final icon =
        isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amount = hareket.netAmount.abs();
    final sign = isIn ? '+' : '-';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Padding(
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
                  Text(
                    hareket.cariTitle.isEmpty ? '(Cari yok)' : hareket.cariTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${hareket.transactionTypeName} · ${Formatters.relativeTime(hareket.date)}',
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
      ),
    );
  }
}
