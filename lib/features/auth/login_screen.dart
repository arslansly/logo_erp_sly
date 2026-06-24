import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../settings/settings_screen.dart';
import '../shell/main_shell.dart';
import 'auth_service.dart';

/// V2 · "Editorial Manifesto" giriş ekranı
/// ─────────────────────────────────────────────────────────────────
/// Hedef: yatırımcı/patron sunumlarında premium, satışta wow.
/// Layout:
///   ┌──────────────────────────────┐
///   │ ● LOGO · MOBİL        v 9.0  │  ← mono mini header
///   │                              │
///   │ Şirketinizin                 │  ← staggered, dev başlık
///   │ nabzı  ────                  │  ← accent underline anim
///   │ cebinizde.                   │
///   │                              │
///   │ Tahsilattan vade alarmına... │  ← subtitle
///   │                              │
///   │     ~~~^~~~^~~~^~~~          │  ← sürekli ECG nabız çizgisi
///   │                              │
///   │ KULLANICI                    │
///   │ demir.aksoy  ──────          │  ← hairline border
///   │ ŞİFRE                        │
///   │ ●●●●●●●●  ──────             │
///   │                              │
///   │ GİRİŞ YAP            (→)     │  ← mono label + halkalı CTA
///   └──────────────────────────────┘
class _EdPalette {
  static const bg          = Color(0xFF000000);
  static const text        = Color(0xFFFFFFFF);
  static const textDim     = Color(0x80FFFFFF); // %50
  static const textMute    = Color(0x59FFFFFF); // %35
  static const hairline    = Color(0x29FFFFFF); // %16
  static const hairlineLit = Color(0x73FFFFFF); // %45
  static const accent      = Color(0xFF10B981);
  static const accentLight = Color(0xFF34D399);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Form state ──
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Animasyon controller'ları ──
  /// Sürekli dönen — ECG nabız, CTA halka, dot pulse, cursor blink
  late final AnimationController _cosmosCtrl;

  /// Sahne girişi — tek-yön staggered (0..1)
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _cosmosCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _usernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));

    _loadLastUsername();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _cosmosCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLastUsername() async {
    final lastUser = await authService.getLastUsername();
    if (lastUser != null && mounted) {
      setState(() => _usernameCtrl.text = lastUser);
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Kullanıcı adı ve şifre zorunlu');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await authService.login(username, password);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EdPalette.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── ECG nabız çizgisi (sürekli akan) ──
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _cosmosCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _EcgPainter(_cosmosCtrl.value),
                ),
              ),
            ),
          ),

          // ── İçerik ──



SafeArea(
child: LayoutBuilder(
builder: (context, constraints) {
return SingleChildScrollView(
// klavye yüksekliği kadar alt padding — içerik klavyenin üstünde kalır
padding: EdgeInsets.only(
bottom: MediaQuery.of(context).viewInsets.bottom,
),
child: ConstrainedBox(
constraints: BoxConstraints(minHeight: constraints.maxHeight),
child: IntrinsicHeight(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 28),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
                  const SizedBox(height: 12),

                  // Header: mono mini etiketler
                  _StaggeredFade(
                    controller: _entryCtrl,
                    begin: 0.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BrandTag(cosmos: _cosmosCtrl),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MonoLabel(text: 'v 9.0'),
                            const SizedBox(width: 14),
                            _SettingsButton(onTap: _openSettings),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 56),

                  // ── Manifesto başlık ──
                  _EditorialHeadline(
                    controller: _entryCtrl,
                    lines: const [
                      _HeadlineLine('Şirketinizin'),
                      _HeadlineLine('nabzı', accent: true),
                      _HeadlineLine('cebinizde.'),
                    ],
                  ),

                  const SizedBox(height: 26),

                  _StaggeredFade(
                    controller: _entryCtrl,
                    begin: 0.55,
                    child: SizedBox(
                      width: 270,
                      child: Text(
                        'Tahsilattan vade alarmına, fatura kesmekten cari ekstresine — hepsi tek dokunuşla.',
                        style: AppTypography.body.copyWith(
                          color: _EdPalette.textDim,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Hata mesajı
                  if (_errorMessage != null) ...[
                    _StaggeredFade(
                      controller: _entryCtrl,
                      begin: 0.65,
                      child: _buildError(),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Hairline input: Kullanıcı ──
                  _StaggeredFade(
                    controller: _entryCtrl,
                    begin: 0.7,
                    child: _HairlineInput(
                      label: 'KULLANICI',
                      controller: _usernameCtrl,
                      focusNode: _usernameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Hairline input: Şifre ──
                  _StaggeredFade(
                    controller: _entryCtrl,
                    begin: 0.78,
                    child: _HairlineInput(
                      label: 'ŞİFRE',
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      obscure: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      trailing: GestureDetector(
                        onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _EdPalette.textMute,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Alt CTA satırı ──
                  _StaggeredFade(
                    controller: _entryCtrl,
                    begin: 0.88,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _isLoading ? 'GİRİŞ YAPILIYOR…' : 'GİRİŞ YAP',
                          style: AppTypography.caption.copyWith(
                            color: _EdPalette.textDim,
                            fontSize: 11,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w500,
                            fontFamilyFallback: const ['monospace'],
                          ),
                        ),
                        _ArrowCta(
                          loading: _isLoading,
                          onTap: _login,
                          cosmos: _cosmosCtrl,
                        ),
                      ],
                    ),
                  ),
  const SizedBox(height: 28),
],
),
),
),
),
);
},
),
),
        ],
      ),
    );


  }
  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.negative.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.negative.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.negative, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.negative,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Header parçaları
// ═══════════════════════════════════════════════════════════════════

class _BrandTag extends StatelessWidget {
  final AnimationController cosmos;
  const _BrandTag({required this.cosmos});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Küçük sembol logosu — pulsing glow efektli
        AnimatedBuilder(
          animation: cosmos,
          builder: (_, __) {
            final t = 0.5 + 0.5 * math.sin(cosmos.value * 2 * math.pi * 2);
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _EdPalette.accent.withValues(alpha: 0.45 * t),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/sembol.png',
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _MonoLabel(text: 'LOGO · MOBİL'),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(
          Icons.settings_outlined,
          color: _EdPalette.textDim,
          size: 18,
        ),
      ),
    );
  }
}

class _MonoLabel extends StatelessWidget {
  final String text;
  const _MonoLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: _EdPalette.textDim,
        fontSize: 11,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w500,
        fontFamilyFallback: const ['monospace'],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Manifesto başlık
// ═══════════════════════════════════════════════════════════════════

class _HeadlineLine {
  final String text;
  final bool accent;
  const _HeadlineLine(this.text, {this.accent = false});
}

class _EditorialHeadline extends StatelessWidget {
  final AnimationController controller;
  final List<_HeadlineLine> lines;
  const _EditorialHeadline({required this.controller, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines.length, (i) {
        final lineStart = 0.08 + i * 0.14;
        final lineEnd = math.min(1.0, lineStart + 0.40);
        final lineAnim = CurvedAnimation(
          parent: controller,
          curve: Interval(lineStart, lineEnd, curve: Curves.easeOutCubic),
        );
        final underlineAnim = CurvedAnimation(
          parent: controller,
          curve: Interval(
            math.min(1.0, lineStart + 0.18),
            math.min(1.0, lineStart + 0.42),
            curve: Curves.easeOutCubic,
          ),
        );
        final l = lines[i];
        return Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
          child: AnimatedBuilder(
            animation: lineAnim,
            builder: (_, __) => Opacity(
              opacity: lineAnim.value,
              child: Transform.translate(
                offset: Offset(0, (1 - lineAnim.value) * 20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      l.text,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 50,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2.2,
                        color: _EdPalette.text,
                        height: 1.0,
                      ),
                    ),
                    if (l.accent)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 4,
                        child: AnimatedBuilder(
                          animation: underlineAnim,
                          builder: (_, __) => Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: underlineAnim.value,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _EdPalette.accent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Hairline input
// ═══════════════════════════════════════════════════════════════════

class _HairlineInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  const _HairlineInput({
    required this.label,
    required this.controller,
    required this.focusNode,
    this.obscure = false,
    this.textInputAction,
    this.onSubmitted,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: _EdPalette.textDim,
            fontSize: 9.5,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: const ['monospace'],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscure,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                cursorColor: _EdPalette.accent,
                cursorWidth: 2,
                style: const TextStyle(
                  color: _EdPalette.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  fontFamily: 'Inter',
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 10),
                  border: InputBorder.none,
                  hintText: null,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: trailing!,
              ),
            ],
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          height: focused ? 1.5 : 1,
          decoration: BoxDecoration(
            color: focused ? _EdPalette.accent : _EdPalette.hairline,
            boxShadow: focused
                ? [
              BoxShadow(
                color: _EdPalette.accent.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ]
                : null,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CTA — yuvarlak ok butonu + sürekli yayılan halka
// ═══════════════════════════════════════════════════════════════════

class _ArrowCta extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  final AnimationController cosmos;
  const _ArrowCta({
    required this.loading,
    required this.onTap,
    required this.cosmos,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sürekli yayılan halka
            if (!loading)
              AnimatedBuilder(
                animation: cosmos,
                builder: (_, __) {
                  final t = (cosmos.value * 1.5) % 1.0; // 0..1, 2.4s'de bir
                  return Container(
                    width: 54 + 32 * t,
                    height: 54 + 32 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _EdPalette.accent
                            .withValues(alpha: (1 - t) * 0.6),
                        width: 1.8,
                      ),
                    ),
                  );
                },
              ),
            // Ana buton
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: loading
                    ? Colors.white.withValues(alpha: 0.10)
                    : _EdPalette.accent,
                boxShadow: loading
                    ? null
                    : [
                  BoxShadow(
                    color: _EdPalette.accent.withValues(alpha: 0.45),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: loading
                  ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
                  : const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Staggered fade helper
// ═══════════════════════════════════════════════════════════════════

class _StaggeredFade extends StatelessWidget {
  final AnimationController controller;
  final double begin;
  final double slide;
  final Widget child;

  const _StaggeredFade({
    required this.controller,
    required this.begin,
    required this.child,
    this.slide = 14,
  });

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, math.min(1.0, begin + 0.35),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * slide),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ECG nabız çizgisi — sürekli soldan sağa akar
// ═══════════════════════════════════════════════════════════════════

class _EcgPainter extends CustomPainter {
  final double t; // 0..1
  _EcgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Çizgi ekranın alt orta bölgesinde yer alır.
    final yMid = size.height * 0.62;
    final amplitude = 22.0;

    // Tek bir nabız deseni — bu örüntüyü yatayda tekrarlıyoruz, sonra
    // dashOffset'i hareket ettirerek "akan" his veriyoruz.
    final patternW = 110.0;
    final totalLen = size.width + patternW;
    final shift = t * patternW; // her döngüde bir pattern kadar kayma

    final path = Path();
    path.moveTo(-patternW + shift, yMid);

    double x = -patternW + shift;
    while (x < size.width + patternW) {
      // düz çizgi
      path.lineTo(x + 30, yMid);
      // yukarı sivri
      path.lineTo(x + 38, yMid - amplitude * 0.55);
      // aşağı sivri (büyük)
      path.lineTo(x + 46, yMid + amplitude);
      // tekrar yukarı
      path.lineTo(x + 54, yMid - amplitude * 0.3);
      // düze dön
      path.lineTo(x + 62, yMid);
      // boşluk
      x += patternW;
      path.lineTo(x, yMid);
    }

    // Çizgi üzerine soldan sağa giden parlaklık gradient'i
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _EdPalette.accent.withValues(alpha: 0.0),
        _EdPalette.accent.withValues(alpha: 0.85),
        _EdPalette.accentLight.withValues(alpha: 0.9),
        _EdPalette.accent.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, yMid - amplitude * 1.5, size.width, amplitude * 3),
      );

    canvas.drawPath(path, paint);

    // Hafif glow için ikinci çizim (geniş, opak değil)
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, yMid - amplitude * 1.5, size.width, amplitude * 3),
      );
    canvas.drawPath(path, glow);
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.t != t;
}