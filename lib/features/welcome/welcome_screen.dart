import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../auth/login_screen.dart';


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Arka plan: derin mor gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  AppColors.violetDark,
                  AppColors.violetMid,
                  AppColors.violet,
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),

          // ── Dekoratif glow lekeleri ──
          Positioned(
            top: -80,
            right: -80,
            child: _buildGlowOrb(
              size: 280,
              color: AppColors.accentLight.withValues(alpha: 0.30),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: _buildGlowOrb(
              size: 320,
              color: AppColors.pink.withValues(alpha: 0.22),
            ),
          ),

          // ── Ana içerik ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Logo (çift renkli glow ile)
                  _buildLogo(),

                  const SizedBox(height: 36),

                  // Başlık: "Logo" + gradient "Mobil"
                  _buildTitle(),

                  const SizedBox(height: 12),

                  Text(
                    'Cebinizdeki ERP.\nHer zaman, her yerde.',
                    style: AppTypography.body.copyWith(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Canlı stat etiketi
                  _buildLiveStat(),

                  const Spacer(),

                  // Feature kartları (teal + pembe)
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.people_outline_rounded,
                          title: 'Cari',
                          subtitle: 'Bakiye, hareket,\nvade analizi',
                          tint: AppColors.accent,
                          iconColor: AppColors.accentLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.receipt_long_outlined,
                          title: 'Fatura',
                          subtitle: 'Anlık erişim,\ntek dokunuş',
                          tint: AppColors.pink,
                          iconColor: AppColors.pinkLight,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // CTA: teal→cyan gradient
                  _buildCtaButton(context),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      'POWERED BY LOGO ERP_SLY',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white38,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dış glow halkası
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent.withValues(alpha: 0.35),
                AppColors.pink.withValues(alpha: 0.25),
              ],
            ),
          ),
        ),
        // İç container — logo görseli
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.08),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.45),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Image.asset(
              'assets/images/sembol.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Text(
          'Logo ',
          style: AppTypography.display.copyWith(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),
        // "Mobil" kelimesine gradient efekti
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.accentLight, AppColors.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Mobil',
            style: AppTypography.display.copyWith(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStat() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        border: Border.all(
          color: AppColors.accentLight.withValues(alpha: 0.4),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.liveGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.liveGreen.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'LOGO ERP bağlı',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.18),
            tint.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tint.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTypography.h2.copyWith(
              color: Colors.white,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: Colors.white60,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.accent, AppColors.cyan],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Başla',
                  style: AppTypography.button.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}