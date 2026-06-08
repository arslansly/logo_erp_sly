import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../cari/cari_detay_screen.dart';
import '../siparis/siparis_detay_screen.dart';
import 'acik_siparisler_screen.dart';
import 'riskli_cariler_screen.dart';
import 'saha_model.dart';
import 'saha_service.dart';
import 'saha_widgets.dart';

/// Saha paneli — satışçı odaklı: açık (sevk bekleyen) siparişler, satışçı
/// kırılımı ve riskli müşteriler. Yetki: "view_saha_panel" (sekme yetkiye bağlı gelir).
class SahaScreen extends StatefulWidget {
  const SahaScreen({super.key});

  @override
  State<SahaScreen> createState() => _SahaScreenState();
}

class _SahaScreenState extends State<SahaScreen> {
  List<SahaSatisci>? _satiscilar;
  int? _selectedRef; // null = tüm satışçılar

  SahaOzet? _ozet;
  List<SahaAcikSiparis>? _acikSiparisler;
  List<SahaRiskliCari>? _riskliCariler;

  bool _loadingSatiscilar = true;
  bool _loadingScoped = true;
  String? _error;

  static const int _onizlemeAdet = 5; // panelde gösterilen önizleme satırı

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loadingSatiscilar = true;
      _error = null;
    });
    try {
      final satiscilar = await sahaService.getSatiscilar();
      if (!mounted) return;
      setState(() {
        _satiscilar = satiscilar;
        _loadingSatiscilar = false;
      });
      await _loadScoped();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingSatiscilar = false;
        _loadingScoped = false;
      });
    }
  }

  Future<void> _loadScoped() async {
    setState(() {
      _loadingScoped = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        sahaService.getOzet(satisciRef: _selectedRef),
        sahaService.getAcikSiparisler(satisciRef: _selectedRef, limit: _onizlemeAdet),
        sahaService.getRiskliCariler(satisciRef: _selectedRef, limit: _onizlemeAdet),
      ]);
      if (!mounted) return;
      setState(() {
        _ozet = results[0] as SahaOzet;
        _acikSiparisler = results[1] as List<SahaAcikSiparis>;
        _riskliCariler = results[2] as List<SahaRiskliCari>;
        _loadingScoped = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingScoped = false;
      });
    }
  }

  void _selectSatisci(int? ref) {
    if (ref == _selectedRef) return;
    setState(() => _selectedRef = ref);
    _loadScoped();
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
          onRefresh: _loadAll,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSatisciSecici(),
                if (_error != null)
                  _buildErrorState()
                else if (_loadingScoped)
                  _buildSkeleton()
                else ...[
                  _buildOzetHero(),
                  if ((_ozet?.limitAsanSayisi ?? 0) > 0) _buildLimitAsanBanner(),
                  _buildAcikSiparislerSection(),
                  _buildRiskliCarilerSection(),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentDark, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.storefront_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saha Paneli', style: AppTypography.h2.copyWith(fontSize: 18)),
                Text('Açık siparişler & müşteri riski',
                    style: AppTypography.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Satışçı seçici (yatay çipler — leaderboard + filtre) ───
  Widget _buildSatisciSecici() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 14),
      child: _loadingSatiscilar
          ? _seciciSkeleton()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _satisciChip(
                    label: 'Tümü',
                    sub: '${_satiscilar?.length ?? 0} satışçı',
                    selected: _selectedRef == null,
                    onTap: () => _selectSatisci(null),
                  ),
                  for (final s in _satiscilar ?? <SahaSatisci>[]) ...[
                    const SizedBox(width: 8),
                    _satisciChip(
                      label: s.ad,
                      sub: '${Formatters.currencyCompact(s.acikSiparisTutar)} · ${s.acikSiparisAdet}',
                      selected: _selectedRef == s.id,
                      onTap: () => _selectSatisci(s.id),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _satisciChip({
    required String label,
    required String sub,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minWidth: 96, maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [AppColors.accentDark, AppColors.accent])
              : null,
          color: selected ? null : AppColors.slate100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.slate800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: selected ? Colors.white70 : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Özet hero (koyu kart) ───
  Widget _buildOzetHero() {
    final o = _ozet!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                const Icon(Icons.local_shipping_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Açık sipariş · ${o.satisciAd}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption
                          .copyWith(color: Colors.white70, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Formatters.currency(o.acikSiparisTutar),
                maxLines: 1,
                style: AppTypography.display.copyWith(
                  color: Colors.white,
                  fontSize: 30,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('${o.acikSiparisAdet} sipariş · ${o.musteriSayisi} müşteri',
                style: AppTypography.caption
                    .copyWith(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _heroSplit(
                    'Riskli müşteri',
                    '${o.riskliCariSayisi}',
                    'vadesi geçen',
                    AppColors.pinkLight,
                    Icons.warning_amber_rounded,
                  ),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.12)),
                Expanded(
                  child: _heroSplit(
                    'Vadesi geçen',
                    Formatters.currencyCompact(o.vadesiGecenToplam),
                    'tahsil edilecek',
                    AppColors.liveGreen,
                    Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroSplit(
      String label, String value, String sub, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption
                        .copyWith(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.h2.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 1),
          Text(sub,
              style: AppTypography.caption
                  .copyWith(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Kredi limitini aşan müşteri uyarısı (yalnızca limit kullanan firmalarda) ───
  Widget _buildLimitAsanBanner() {
    final n = _ozet!.limitAsanSayisi;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Material(
        color: AppColors.negativeBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _push(RiskliCarilerScreen(
            satisciRef: _selectedRef,
            satisciAd: _ozet?.satisciAd ?? 'Tüm satışçılar',
          )),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.gpp_maybe_rounded,
                    color: AppColors.negative, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$n müşteri kredi limitini aştı',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.negative,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.negative, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Açık siparişler ───
  Widget _buildAcikSiparislerSection() {
    final list = _acikSiparisler ?? const <SahaAcikSiparis>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Açık siparişler',
            'sevk bekleyen',
            onSeeAll: list.length >= _onizlemeAdet
                ? () => _push(AcikSiparislerScreen(
                      satisciRef: _selectedRef,
                      satisciAd: _ozet?.satisciAd ?? 'Tüm satışçılar',
                    ))
                : null,
          ),
          if (list.isEmpty)
            const SahaEmptyState(
              icon: Icons.check_circle_outline_rounded,
              mesaj: 'Sevk bekleyen sipariş yok',
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < list.length; i++) ...[
                    AcikSiparisTile(
                      siparis: list[i],
                      showSatisci: _selectedRef == null,
                      onTap: () =>
                          _push(SiparisDetayScreen(id: list[i].id)),
                    ),
                    if (i != list.length - 1) const SahaDivider(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Riskli müşteriler ───
  Widget _buildRiskliCarilerSection() {
    final list = _riskliCariler ?? const <SahaRiskliCari>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Riskli müşteriler',
            'vadesi geçen alacak',
            onSeeAll: list.length >= _onizlemeAdet
                ? () => _push(RiskliCarilerScreen(
                      satisciRef: _selectedRef,
                      satisciAd: _ozet?.satisciAd ?? 'Tüm satışçılar',
                    ))
                : null,
          ),
          if (list.isEmpty)
            const SahaEmptyState(
              icon: Icons.verified_user_outlined,
              mesaj: 'Vadesi geçen alacak yok',
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < list.length; i++) ...[
                    RiskliCariTile(
                      cari: list[i],
                      onTap: () => _push(CariDetayScreen(cariId: list[i].cariId)),
                    ),
                    if (i != list.length - 1) const SahaDivider(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String sub, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: AppTypography.h3.copyWith(fontSize: 14)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(sub, style: AppTypography.caption.copyWith(fontSize: 11)),
          ),
          const Spacer(),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tümü',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        )),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.accent),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Skeleton ───
  Widget _seciciSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.slate200,
      highlightColor: AppColors.slate100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(
            4,
            (_) => Container(
              width: 104,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.slate200,
      highlightColor: AppColors.slate100,
      child: Column(
        children: [
          _skelBox(height: 180, radius: 22),
          _skelBox(height: 220),
          _skelBox(height: 180),
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
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.slate400),
            const SizedBox(height: 16),
            Text(_error ?? 'Hata',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.slate600)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
