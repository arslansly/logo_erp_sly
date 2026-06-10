import 'package:flutter/material.dart';

/// Bir sayıyı 0'dan hedef değere doğru sayarak (count-up) gösterir.
/// Finansal hero kartlarında premium bir "canlılık" hissi verir.
///
/// `formatter` her kareyi metne çevirir (ör. `Formatters.currency`).
/// Değer ilk göründüğünde animasyon oynar; aynı değerle yeniden build
/// edilince tekrar oynamaz (TweenAnimationBuilder `end` değişmedikçe sabit).
class AnimatedCount extends StatelessWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle style;
  final Duration duration;

  const AnimatedCount({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(formatter(v), style: style),
    );
  }
}
