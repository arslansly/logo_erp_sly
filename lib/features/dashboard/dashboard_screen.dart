import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/animated_count.dart';
import '../../core/utils/formatters.dart';
import 'dashboard_model.dart';
import 'dashboard_service.dart';
import 'vadesi_gecen_cariler_screen.dart';
import 'bugun_tahsilatlar_screen.dart';
import 'son_hareketler_screen.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../cari/cari_list_screen.dart';
import '../fatura/fatura_list_screen.dart';
import '../malzeme/malzeme_list_screen.dart';
import '../rapor/rapor_hub_screen.dart';
import '../ai/ai_chat_screen.dart';
import '../tahsilat/tahsilat_liste_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardOzet? _ozet;
  List<SonHareket>? _hareketler;
  String? _error;
  bool _isLoading = true;
  bool _hideBalance = false;  // ← YENİ
  String _userName = '';  // ← YENİ

  @override
  void initState() {
    super.initState();
    _loadUserName();   // ← YENİ
    _loadData();
  }

  Future<void> _loadUserName() async {
    final name = await authService.getUserName();
    if (mounted && name != null) {
      setState(() => _userName = name);
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        dashboardService.getOzet(),
        dashboardService.getSonHareketler(limit: 5),
      ]);
      if (!mounted) return;
      setState(() {
        _ozet = results[0] as DashboardOzet;
        _hareketler = results[1] as List<SonHareket>;
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                // Şirket finansal panelleri (toplam alacak + KPI'lar) — yetkiye bağlı.
                // Kartlar açılışta kademeli olarak içeri kayar (premium giriş hissi).
                if (authService.perms.canViewDashboardFinancials) ...[
                  FadeSlideIn(child: _buildHeroCard()),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: _buildMiniKpis(),
                  ),
                ],
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _buildQuickActions(),
                ),
                // Şirket raporları kısayolu — yetkiye bağlı.
                if (authService.perms.canViewReports)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: _buildRaporlarKart(),
                  ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 320),
                  child: _buildSonHareketler(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Üst başlık (selamlama + bildirim + avatar) ───
  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selamla(),
                  style: AppTypography.caption.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  _userName.isNotEmpty ? _userName : 'Hoş geldiniz',
                  style: AppTypography.h2.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatScreen()),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.violet],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.auto_awesome, size: 19, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _showSonIslemBildirim,
            borderRadius: BorderRadius.circular(12),
            child: _buildIconButton(
              Icons.notifications_outlined,
              hasBadge: _hareketler != null && _hareketler!.isNotEmpty,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _showHesapMenu,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.slate800,
                borderRadius: BorderRadius.circular(50),
              ),
              alignment: Alignment.center,
              child: Text(
                _getInitials(_userName),
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bildirim: en son yapılan işlem ───
  void _showSonIslemBildirim() {
    final sonHareket =
        (_hareketler != null && _hareketler!.isNotEmpty) ? _hareketler!.first : null;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text('Son işlem', style: AppTypography.h3),
                ],
              ),
              const SizedBox(height: 14),
              if (sonHareket != null)
                SonHareketRow(hareket: sonHareket)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Henüz hareket yok',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.slate500)),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openTumHareketler();
                  },
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: const Text('Tüm hareketler'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hesap menüsü: çıkış yap ───
  void _showHesapMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.slate800,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getInitials(_userName),
                      style: AppTypography.h3
                          .copyWith(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName.isNotEmpty ? _userName : 'Kullanıcı',
                          style: AppTypography.h3.copyWith(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Oturum açık',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.slate500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _logout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Çıkış Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.negative,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openTumHareketler() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SonHareketlerScreen()),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Widget _buildIconButton(IconData icon, {bool hasBadge = false}) {
    return Stack(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.slate600, size: 20),
        ),
        if (hasBadge)
          Positioned(
            top: 7,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.negative,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.slate100, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Hero kart: toplam alacak (koyu, büyük rakam) ───
  Widget _buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(22),
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
            Row(
              children: [
                Text(
                  'Toplam alacak',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _hideBalance = !_hideBalance),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _hideBalance
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              _buildShimmer(width: 200, height: 36, onDark: true)
            else if (_hideBalance)
              Text(
                '₺ • • • • • • •',
                style: AppTypography.display.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  letterSpacing: 4,
                ),
              )
            else
              AnimatedCount(
                value: _ozet?.toplamAlacak ?? 0,
                formatter: Formatters.currency,
                style: AppTypography.display.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  letterSpacing: -0.8,
                ),
              ),
            // Gerçek trend — backend'den (geçen aya göre net değişim).
            // Veri yoksa (trendYuzde == null) rozet hiç gösterilmez.
            if (!_isLoading && _ozet?.trendYuzde != null) ...[
              const SizedBox(height: 14),
              _buildTrendRow(_ozet!.trendYuzde!),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Gerçek trend rozeti (hero içinde) ───
  Widget _buildTrendRow(double trend) {
    final up = trend >= 0;
    final color = up ? AppColors.liveGreen : AppColors.pinkLight;
    final pct = trend.abs().toStringAsFixed(1).replaceAll('.', ',');
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                '%$pct',
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Geçen aya göre',
          style: AppTypography.caption.copyWith(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ─── Mini KPI: Vadesi geçen + Bugün tahsilat ───
  Widget _buildMiniKpis() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniKpi(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.negative,
              iconBg: AppColors.negativeBg,
              label: 'Vadesi geçen',
              value: _ozet?.vadesiGecen ?? 0,
              extra: _ozet != null && _ozet!.vadesiGecenCariSayisi > 0
                  ? '${_ozet!.vadesiGecenCariSayisi} cari'
                  : null,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VadesiGecenCarilerScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMiniKpi(
              icon: Icons.payments_rounded,
              iconColor: AppColors.positive,
              iconBg: AppColors.positiveBg,
              label: 'Bugün tahsilat',
              value: _ozet?.bugunTahsilat ?? 0,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BugunTahsilatlarScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKpi({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required double value,
    String? extra,
    VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTypography.caption.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 3),
              _isLoading
                  ? _buildShimmer(width: 90, height: 16)
                  : Text(
                Formatters.currencyCompact(value),
                style: AppTypography.h2.copyWith(
                  color: AppColors.slate900,
                  fontSize: 16,
                ),
              ),
              if (extra != null) ...[
                const SizedBox(height: 2),
                Text(
                  extra,
                  style: AppTypography.caption.copyWith(
                    color: iconColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hızlı işlemler ızgarası ───
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Hızlı işlemler',
                style: AppTypography.h3.copyWith(fontSize: 14)),
          ),
          Row(
            children: [
              Expanded(child: _buildAction(
                Icons.search_rounded, 'Cari ara',
                const Color(0xFFEEF2FF), const Color(0xFF4338CA),
                onTap: () => _push(const CariListScreen()),
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildAction(
                Icons.receipt_long_outlined, 'Faturalar',
                AppColors.warningBg, AppColors.warning,
                onTap: () => _push(const FaturaListScreen()),
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildAction(
                Icons.payments_outlined, 'Tahsilat',
                AppColors.positiveBg, AppColors.positive,
                onTap: () => _push(const TahsilatListeScreen()),
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildAction(
                Icons.inventory_2_outlined, 'Stok',
                const Color(0xFFF3E8FF), const Color(0xFF7E22CE),
                onTap: () => _push(const MalzemeListScreen()),
              )),
            ],
          ),
        ],
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  // ─── Raporlar kısayol kartı ───
  Widget _buildRaporlarKart() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _push(const RaporHubScreen()),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.accentDark, AppColors.accent],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.bar_chart_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Raporlar',
                          style: AppTypography.h3
                              .copyWith(color: Colors.white, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('Cari, vade ve stok raporlarını al ve paylaş',
                          style: AppTypography.caption
                              .copyWith(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, Color bg, Color fg,
      {VoidCallback? onTap}) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11, color: AppColors.slate700,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Son hareketler listesi ───
  Widget _buildSonHareketler() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                Text('Son hareketler',
                    style: AppTypography.h3.copyWith(fontSize: 14)),
                const Spacer(),
                InkWell(
                  onTap: _openTumHareketler,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    child: Text('Tümü',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        )),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            _buildErrorState()
          else if (_isLoading)
            _buildHareketlerSkeleton()
          else if (_hareketler == null || _hareketler!.isEmpty)
              _buildEmptyHareket()
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: List.generate(_hareketler!.length, (i) {
                    final h = _hareketler![i];
                    final isLast = i == _hareketler!.length - 1;
                    return Column(
                      children: [
                        _buildHareketRow(h),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Container(
                                height: 0.5, color: AppColors.slate200),
                          ),
                      ],
                    );
                  }),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildHareketRow(SonHareket h) {
    final isIn = h.isTahsilat; // para girdi mi?
    final color = isIn ? AppColors.positive : AppColors.negative;
    final bg = isIn ? AppColors.positiveBg : AppColors.negativeBg;
    final icon = isIn
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final amount = h.netAmount.abs();
    final sign = isIn ? '+' : '-';

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
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
      ),
    );
  }

  // ─── Yardımcı widget'lar ───
  // Gerçek animasyonlu shimmer. `onDark` → koyu hero kartı için açık tonlar.
  Widget _buildShimmer(
      {double width = 100, double height = 16, bool onDark = false}) {
    return Shimmer.fromColors(
      baseColor: onDark
          ? Colors.white.withValues(alpha: 0.18)
          : AppColors.slate200,
      highlightColor: onDark
          ? Colors.white.withValues(alpha: 0.45)
          : AppColors.slate100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  // Son hareketler için satır yapısını taklit eden gerçek shimmer iskeleti.
  Widget _buildHareketlerSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.slate200,
        highlightColor: AppColors.slate100,
        child: Column(
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: 90,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 56,
                    height: 13,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyHareket() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text('Henüz hareket yok',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.slate500,
            )),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.negativeBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.negative, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error ?? 'Hata',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.negative,
                )),
          ),
        ],
      ),
    );
  }

  String _selamla() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }
}