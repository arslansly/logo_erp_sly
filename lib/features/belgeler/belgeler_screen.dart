import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../fatura/fatura_list_screen.dart';
import '../irsaliye/irsaliye_list_screen.dart';
import '../siparis/siparis_list_screen.dart';

/// Belgeler şemsiye ekranı — Fatura/İrsaliye/Sipariş kartları.
class BelgelerScreen extends StatelessWidget {
  const BelgelerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Belgeler'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppTypography.h2,
        foregroundColor: AppColors.slate900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _BelgeKarti(
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.accent,
            iconBg: AppColors.accent.withValues(alpha: 0.12),
            baslik: 'Faturalar',
            altyazi: 'Satış, satınalma, iade, hizmet',
            aktif: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaturaListScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _BelgeKarti(
            icon: Icons.local_shipping_rounded,
            iconColor: AppColors.violet,
            iconBg: AppColors.violet.withValues(alpha: 0.12),
            baslik: 'İrsaliyeler',
            altyazi: 'Satış, satınalma, iade',
            aktif: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IrsaliyeListScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _BelgeKarti(
            icon: Icons.assignment_rounded,
            iconColor: AppColors.cyan,
            iconBg: AppColors.cyan.withValues(alpha: 0.12),
            baslik: 'Siparişler',
            altyazi: 'Satış / satınalma siparişleri',
            aktif: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SiparisListScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _BelgeKarti extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String baslik;
  final String altyazi;
  final bool aktif;
  final VoidCallback? onTap;

  const _BelgeKarti({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.baslik,
    required this.altyazi,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !aktif;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: disabled ? AppColors.slate100 : iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: disabled ? AppColors.slate400 : iconColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          baslik,
                          style: AppTypography.h2.copyWith(
                            color: disabled ? AppColors.slate400 : AppColors.slate900,
                          ),
                        ),
                        if (disabled) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Yakında',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      altyazi,
                      style: AppTypography.bodySmall.copyWith(
                        color: disabled ? AppColors.slate400 : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: disabled ? AppColors.slate300 : AppColors.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
