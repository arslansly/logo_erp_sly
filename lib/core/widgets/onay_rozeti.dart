import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Taslak onay durumu rozeti — liste kartlarında gösterilir.
/// status: 'Pending' | 'Approved' | 'Rejected' (null/diğer → hiçbir şey).
class OnayRozeti extends StatelessWidget {
  final String? status;
  const OnayRozeti({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (renk, bg, ikon, metin) = switch (status) {
      'Pending' => (
          AppColors.warning,
          AppColors.warningBg,
          Icons.hourglass_top_rounded,
          'Onay bekliyor'
        ),
      'Approved' => (
          AppColors.positive,
          AppColors.positiveBg,
          Icons.check_circle_rounded,
          'Onaylandı'
        ),
      'Rejected' => (
          AppColors.negative,
          AppColors.negativeBg,
          Icons.cancel_rounded,
          'Reddedildi'
        ),
      _ => (Colors.transparent, Colors.transparent, Icons.circle, ''),
    };
    if (metin.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 12, color: renk),
          const SizedBox(width: 4),
          Text(
            metin,
            style: AppTypography.caption.copyWith(
              color: renk,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
