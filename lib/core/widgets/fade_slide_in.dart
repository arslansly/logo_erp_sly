import 'package:flutter/material.dart';

/// Bir widget'ı yumuşakça aşağıdan yukarı kaydırarak ve solarak içeri getirir.
/// Ekran ilk açıldığında kartların sırayla (kademeli) belirmesi için `delay`
/// ver: 0ms, 80ms, 160ms... Böylece premium bir "giriş" hissi oluşur.
///
/// Sadece ilk yerleşimde bir kez oynar (setState ile yeniden build edilince
/// tekrar tetiklenmez). Cross-cutting olduğu için `core/widgets` altında.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Başlangıçta widget'ın ne kadar aşağıda duracağı (px). Yukarı kayarak gelir.
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offsetY = 16,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    // Kademeli giriş için gecikmeli başlat; bu arada widget atılırsa koru.
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Opacity(
          opacity: _anim.value,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - _anim.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
