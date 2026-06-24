import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Tam ekran barkod tarayıcı. Taranan barkodun ham değerini [Navigator.pop] ile döner.
/// Kullanım: `final barkod = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const BarkodTarayici()));`
class BarkodTarayici extends StatefulWidget {
  const BarkodTarayici({super.key});

  @override
  State<BarkodTarayici> createState() => _BarkodTarayiciState();
}

class _BarkodTarayiciState extends State<BarkodTarayici>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _tarandiMi = false;
  late final AnimationController _scanAnim;
  late final Animation<double> _scanLine;
  bool _fener = false;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLine = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_tarandiMi) return;
    final barkod = capture.barcodes.firstOrNull?.rawValue;
    if (barkod == null || barkod.isEmpty) return;
    _tarandiMi = true;
    _controller.stop();
    if (!mounted) return;
    Navigator.of(context).pop(barkod);
  }

  Future<void> _feneriToggle() async {
    await _controller.toggleTorch();
    if (!mounted) return;
    setState(() => _fener = !_fener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Barkod Tara',
          style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: _fener ? 'Feneri kapat' : 'Feneri aç',
            onPressed: _feneriToggle,
            icon: Icon(
              _fener ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
              color: _fener ? Colors.amber : Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _ScannerOverlay(scanLine: _scanLine),
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Text(
              'Barkodu çerçeve içine getirin',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final Animation<double> scanLine;
  const _ScannerOverlay({required this.scanLine});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scanLine,
      builder: (context, _) {
        return CustomPaint(
          painter: _OverlayPainter(scanProgress: scanLine.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double scanProgress;
  const _OverlayPainter({required this.scanProgress});

  static const double _frameSize = 260.0;
  static const double _cornerLen = 30.0;
  static const double _cornerStroke = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final frame = Rect.fromCenter(
      center: Offset(cx, cy),
      width: _frameSize,
      height: _frameSize,
    );

    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, frame.top), overlayPaint);
    canvas.drawRect(
        Rect.fromLTWH(0, frame.top, frame.left, _frameSize), overlayPaint);
    canvas.drawRect(
        Rect.fromLTWH(frame.right, frame.top, size.width - frame.right, _frameSize),
        overlayPaint);
    canvas.drawRect(
        Rect.fromLTWH(0, frame.bottom, size.width, size.height - frame.bottom),
        overlayPaint);

    final corner = Paint()
      ..color = AppColors.accent
      ..strokeWidth = _cornerStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawCorner(canvas, corner, frame.topLeft, 1, 1);
    _drawCorner(canvas, corner, frame.topRight, -1, 1);
    _drawCorner(canvas, corner, frame.bottomLeft, 1, -1);
    _drawCorner(canvas, corner, frame.bottomRight, -1, -1);

    // Tarama çizgisi
    final lineY = frame.top + _frameSize * scanProgress;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.accent.withValues(alpha: 0.9),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(frame.left, lineY, _frameSize, 2))
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(frame.left + 8, lineY),
      Offset(frame.right - 8, lineY),
      linePaint,
    );
  }

  void _drawCorner(Canvas canvas, Paint paint, Offset origin, double dx, double dy) {
    final x = origin.dx;
    final y = origin.dy;
    canvas.drawLine(Offset(x, y), Offset(x + dx * _cornerLen, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy * _cornerLen), paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.scanProgress != scanProgress;
}
