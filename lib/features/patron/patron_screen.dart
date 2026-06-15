import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/animated_count.dart';
import '../../core/utils/formatters.dart';
import '../auth/auth_service.dart';
import '../onay/onay_model.dart';
import '../onay/onay_service.dart';
import '../onay/onaylar_screen.dart';
import 'patron_model.dart';
import 'patron_service.dart';
import 'banka_hesaplar_screen.dart';
import 'cekler_screen.dart';

/// Patron paneli — net alacak/borç + yaşlandırma, nakit/banka, çek-senet.
/// Yetki: "view_patron_panel" (sekme zaten yetkiye bağlı gelir).
class PatronScreen extends StatefulWidget {
  const PatronScreen({super.key});

  @override
  State<PatronScreen> createState() => _PatronScreenState();
}

class _PatronScreenState extends State<PatronScreen> {
  PatronOzet? _ozet;
  OnayOzet? _onayOzet; // onay bekleyen sayıları (yetkisi varsa)
  String? _error;
  bool _isLoading = true;
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    // Onay bekleyenleri arka planda ayrı çek — patron paneli verisini bloklamasın.
    _loadOnayOzet();
    try {
      final ozet = await patronService.getOzet();
      if (!mounted) return;
      setState(() {
        _ozet = ozet;
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

  // Onay bekleyen sayıları — yalnızca onay yetkisi olan kullanıcı için.
  Future<void> _loadOnayOzet() async {
    if (!authService.perms.canApproveBelge) return;
    try {
      final o = await onayService.getOzet();
      if (mounted) setState(() => _onayOzet = o);
    } catch (_) {
      // Sessiz geç — banner gizli kalır, panel etkilenmez.
    }
  }

  /// Para metni — gizleme açıksa maskeler (patron herkesin önünde açabilsin).
  String _money(double v, {bool compact = false}) {
    if (_hideBalance) return '₺ • • •';
    return compact ? Formatters.currencyCompact(v) : Formatters.currency(v);
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (_onayOzet != null && _onayOzet!.toplam > 0)
                  FadeSlideIn(child: _buildOnayBanner(_onayOzet!)),
                if (_error != null)
                  _buildErrorState()
                else if (_isLoading)
                  _buildSkeleton()
                else ...[
                  FadeSlideIn(child: _buildNetHero()),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: _buildYaslandirma(),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: _buildNakitBanka(),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: _buildCekSenet(),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Başlık ───
  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.violetMid],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.insights_rounded,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patron Paneli', style: AppTypography.h2.copyWith(fontSize: 18)),
                Text('Firma finansal özeti',
                    style: AppTypography.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _hideBalance = !_hideBalance),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _hideBalance
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.slate600,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Onay bekleyenler banner'ı ───
  Widget _buildOnayBanner(OnayOzet o) {
    // Tür kırılımı metni (yalnızca dolu olanlar)
    final parcalar = <String>[
      if (o.fatura > 0) '${o.fatura} fatura',
      if (o.siparis > 0) '${o.siparis} sipariş',
      if (o.irsaliye > 0) '${o.irsaliye} irsaliye',
      if (o.tahsilat > 0) '${o.tahsilat} tahsilat',
      if (o.masraf > 0) '${o.masraf} masraf',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const OnaylarScreen()))
              .then((_) => _loadOnayOzet()),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFB45309), AppColors.warning],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
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
                  alignment: Alignment.center,
                  child: Text('${o.toplam}',
                      style: AppTypography.h1
                          .copyWith(color: Colors.white, fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Onay bekleyen belge',
                          style: AppTypography.h3
                              .copyWith(color: Colors.white, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(parcalar.join(' · '),
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

  // ─── Net durum hero (koyu) ───
  Widget _buildNetHero() {
    final o = _ozet!;
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
            Text('Net bakiye',
                style: AppTypography.caption
                    .copyWith(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            if (_hideBalance)
              Text(
                _money(o.netBakiye),
                style: AppTypography.display.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  letterSpacing: 4,
                ),
              )
            else
              AnimatedCount(
                value: o.netBakiye,
                formatter: Formatters.currency,
                style: AppTypography.display.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  letterSpacing: -0.8,
                ),
              ),
            if (o.trendYuzde != null) ...[
              const SizedBox(height: 12),
              _buildTrendChip(o.trendYuzde!),
            ],
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _heroSplit(
                    'Alacak',
                    _money(o.toplamAlacak, compact: true),
                    '${o.alacakliCariSayisi} cari',
                    AppColors.liveGreen,
                    Icons.south_west_rounded,
                  ),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.12)),
                Expanded(
                  child: _heroSplit(
                    'Borç',
                    _money(o.toplamBorc, compact: true),
                    '${o.borcluCariSayisi} cari',
                    AppColors.pinkLight,
                    Icons.north_east_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChip(double trend) {
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
              Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: color, size: 14),
              const SizedBox(width: 3),
              Text('%$pct',
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('Geçen aya göre',
            style:
                AppTypography.caption.copyWith(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _heroSplit(
      String label, String amount, String sub, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTypography.caption
                      .copyWith(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(amount,
              style: AppTypography.h2
                  .copyWith(color: Colors.white, fontSize: 17)),
          const SizedBox(height: 1),
          Text(sub,
              style: AppTypography.caption
                  .copyWith(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Yaşlandırma ───
  Widget _buildYaslandirma() {
    final o = _ozet!;
    final buckets = <({String label, double value, Color color})>[
      (label: '0-30 gün', value: o.yaslandirma0_30, color: AppColors.warning),
      (label: '31-60 gün', value: o.yaslandirma31_60, color: const Color(0xFFEA580C)),
      (label: '61-90 gün', value: o.yaslandirma61_90, color: const Color(0xFFDC2626)),
      (label: '90+ gün', value: o.yaslandirma90Plus, color: const Color(0xFF991B1B)),
    ];
    final maxVal = buckets.fold<double>(
        0, (m, b) => b.value > m ? b.value : m);

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_bottom_rounded,
                  size: 18, color: AppColors.negative),
              const SizedBox(width: 8),
              Text('Vadesi geçen alacak',
                  style: AppTypography.h3.copyWith(fontSize: 14)),
              const Spacer(),
              Text(_money(o.toplamVadesiGecen, compact: true),
                  style: AppTypography.h3.copyWith(
                    fontSize: 14,
                    color: AppColors.negative,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final b in buckets) ...[
            _agingRow(b.label, b.value, maxVal, b.color),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _agingRow(String label, double value, double maxVal, Color color) {
    final factor = (maxVal > 0) ? (value / maxVal).clamp(0.02, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(label,
              style: AppTypography.caption.copyWith(fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 9,
              color: AppColors.slate100,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value > 0 ? factor : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 78,
          child: Text(
            _money(value, compact: true),
            textAlign: TextAlign.right,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.slate700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Nakit & banka ───
  Widget _buildNakitBanka() {
    final o = _ozet!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Nakit & banka'),
          Row(
            children: [
              Expanded(
                child: _kpiTile(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.accentDark,
                  iconBg: AppColors.accentLight.withValues(alpha: 0.35),
                  label: 'Kasa',
                  // Bu firmada kasa tanımlı değil → ₺0 yerine bilgilendir
                  valueText: o.kasaHesapSayisi == 0
                      ? 'Tanımlı değil'
                      : _money(o.kasaBakiye, compact: true),
                  muted: o.kasaHesapSayisi == 0,
                  sub: o.kasaHesapSayisi > 0 ? '${o.kasaHesapSayisi} kasa' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiTile(
                  icon: Icons.account_balance_rounded,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.slate100,
                  label: 'Banka',
                  valueText: _money(o.bankaBakiye, compact: true),
                  sub: '${o.bankaHesapSayisi} banka',
                  onTap: () => _push(const BankaHesaplarScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Çek & senet ───
  Widget _buildCekSenet() {
    final o = _ozet!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Çek & senet'),
          Row(
            children: [
              Expanded(
                child: _kpiTile(
                  icon: Icons.south_west_rounded,
                  iconColor: AppColors.positive,
                  iconBg: AppColors.positiveBg,
                  label: 'Tahsil edilecek',
                  valueText: _money(o.cekTahsilTutar, compact: true),
                  sub: '${o.cekTahsilAdet} adet',
                  onTap: () => _push(const CeklerScreen(tip: 'tahsil')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiTile(
                  icon: Icons.north_east_rounded,
                  iconColor: AppColors.negative,
                  iconBg: AppColors.negativeBg,
                  label: 'Ödenecek',
                  valueText: _money(o.cekOdemeTutar, compact: true),
                  sub: '${o.cekOdemeAdet} adet',
                  onTap: () => _push(const CeklerScreen(tip: 'odeme')),
                ),
              ),
            ],
          ),
          // Karşılıksız çek uyarısı (kırmızı bayrak)
          if (o.cekKarsiliksizAdet > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.negativeBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.negative.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gpp_bad_rounded,
                      color: AppColors.negative, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${o.cekKarsiliksizAdet} karşılıksız çek',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.negative,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(_money(o.cekKarsiliksizTutar, compact: true),
                      style: AppTypography.h3.copyWith(
                        fontSize: 14,
                        color: AppColors.negative,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ],
          // Tahsil edilecek çek vade dağılımı
          const SizedBox(height: 10),
          _sectionCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahsil edilecek — vade dağılımı',
                    style: AppTypography.caption.copyWith(fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _vadeMini('Vadesi geçmiş', o.cekVadesiGecmis, AppColors.negative),
                    _vadeMini('Bu hafta', o.cekBuHafta, AppColors.warning),
                    _vadeMini('Bu ay', o.cekBuAy, AppColors.accentDark),
                    _vadeMini('Sonra', o.cekSonra, AppColors.slate500),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vadeMini(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 18, height: 3, color: color),
          const SizedBox(height: 6),
          Text(_money(value, compact: true),
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.slate800,
                fontSize: 12,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  // ─── Ortak parçalar ───
  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
        child: Text(t, style: AppTypography.h3.copyWith(fontSize: 14)),
      );

  Widget _sectionCard({required Widget child, EdgeInsets? margin}) => Container(
        margin: margin ?? const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      );

  Widget _kpiTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String valueText,
    String? sub,
    bool muted = false,
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
              Row(
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
                  const Spacer(),
                  if (onTap != null)
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.slate400, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
              const SizedBox(height: 3),
              Text(
                valueText,
                style: AppTypography.h2.copyWith(
                  fontSize: muted ? 13 : 16,
                  color: muted ? AppColors.slate400 : AppColors.slate900,
                  fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub,
                    style: AppTypography.caption
                        .copyWith(fontSize: 11, color: AppColors.slate500)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Skeleton (yükleniyor) ───
  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.slate200,
      highlightColor: AppColors.slate100,
      child: Column(
        children: [
          _skelBox(height: 168, radius: 22),
          Row(children: [
            Expanded(child: _skelBox(height: 96)),
            const SizedBox(width: 10),
            Expanded(child: _skelBox(height: 96)),
          ]),
          _skelBox(height: 150),
        ],
      ),
    );
  }

  Widget _skelBox({double height = 100, double radius = 18}) => Container(
        height: height,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  // ─── Hata ───
  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.slate400),
            const SizedBox(height: 16),
            Text(_error ?? 'Hata',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.slate600)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
