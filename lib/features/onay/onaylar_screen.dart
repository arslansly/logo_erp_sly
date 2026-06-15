import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../masraf/masraf_receipt_image.dart';
import 'onay_model.dart';
import 'onay_service.dart';

/// Onaylar ekranı — satışçının kestiği taslaklar (fatura/sipariş/irsaliye) tek
/// listede; patron/muhasebe onaylar ya da reddeder. Patron panelinden açılır.
class OnaylarScreen extends StatefulWidget {
  const OnaylarScreen({super.key});

  @override
  State<OnaylarScreen> createState() => _OnaylarScreenState();
}

class _OnaylarScreenState extends State<OnaylarScreen> {
  List<OnayBekleyen>? _liste;
  String? _hata;
  bool _yukleniyor = true;
  OnayBelgeTip? _filtre; // null = tümü
  final Set<int> _islemde = {}; // o anda onaylanıyor/reddediliyor olan id'ler

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final l = await onayService.getBekleyenler(tip: _filtre);
      if (!mounted) return;
      setState(() {
        _liste = l;
        _hata = null;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  void _filtreDegistir(OnayBelgeTip? t) {
    if (_filtre == t) return;
    setState(() => _filtre = t);
    _yukle();
  }

  Future<void> _onayla(OnayBekleyen o) async {
    setState(() => _islemde.add(o.id));
    try {
      await onayService.onayla(o.tip, o.id);
      if (!mounted) return;
      setState(() => _liste?.remove(o));
      _bildir('${o.tip.etiket} onaylandı', AppColors.positive);
    } catch (e) {
      if (!mounted) return;
      _bildir(e.toString(), AppColors.negative);
    } finally {
      if (mounted) setState(() => _islemde.remove(o.id));
    }
  }

  Future<void> _reddet(OnayBekleyen o) async {
    final gerekce = await _gerekceSor();
    if (gerekce == null) return; // iptal
    setState(() => _islemde.add(o.id));
    try {
      await onayService.reddet(o.tip, o.id,
          gerekce: gerekce.isEmpty ? null : gerekce);
      if (!mounted) return;
      setState(() => _liste?.remove(o));
      _bildir('${o.tip.etiket} reddedildi', AppColors.slate600);
    } catch (e) {
      if (!mounted) return;
      _bildir(e.toString(), AppColors.negative);
    } finally {
      if (mounted) setState(() => _islemde.remove(o.id));
    }
  }

  // Reddetme gerekçesi sor (boş geçilebilir, iptal → null)
  Future<String?> _gerekceSor() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Reddetme gerekçesi', style: AppTypography.h3),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: AppTypography.body.copyWith(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Opsiyonel — neden reddedildi?',
            hintStyle:
                AppTypography.body.copyWith(color: AppColors.slate500, fontSize: 14),
            filled: true,
            fillColor: AppColors.slate100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Vazgeç',
                style: AppTypography.body.copyWith(color: AppColors.slate600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  void _bildir(String mesaj, Color renk) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(mesaj),
        backgroundColor: renk,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Onaylar'),
        titleTextStyle:
            AppTypography.h1.copyWith(color: AppColors.slate900, fontSize: 22),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildFiltreler(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFiltreler() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 12),
      child: Row(
        children: [
          _FiltreCip(
              label: 'Tümü',
              secili: _filtre == null,
              onTap: () => _filtreDegistir(null)),
          for (final t in OnayBelgeTip.values)
            _FiltreCip(
                label: t.etiket,
                ikon: t.ikon,
                secili: _filtre == t,
                onTap: () => _filtreDegistir(t)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_yukleniyor) return const _OnaySkeleton();
    if (_hata != null) return _buildHata();
    final liste = _liste ?? const [];
    if (liste.isEmpty) return _buildBos();
    return RefreshIndicator(
      onRefresh: _yukle,
      color: AppColors.accent,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: liste.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) => FadeSlideIn(
          delay: Duration(milliseconds: (i * 50).clamp(0, 300)),
          child: _OnayKart(
            veri: liste[i],
            islemde: _islemde.contains(liste[i].id),
            onOnayla: () => _onayla(liste[i]),
            onReddet: () => _reddet(liste[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildBos() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.positiveBg,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: AppColors.positive, size: 42),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Onay bekleyen belge yok',
                      style: AppTypography.h2.copyWith(fontSize: 18)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Tüm taslaklar işlendi.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.slate500)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHata() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.slate400),
            const SizedBox(height: AppSpacing.md),
            Text(_hata ?? 'Hata',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.slate600)),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: _yukle,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filtre çipi ───
class _FiltreCip extends StatelessWidget {
  final String label;
  final IconData? ikon;
  final bool secili;
  final VoidCallback onTap;

  const _FiltreCip({
    required this.label,
    required this.secili,
    required this.onTap,
    this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: secili ? AppColors.primary : AppColors.slate100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ikon != null) ...[
                Icon(ikon,
                    size: 15,
                    color: secili ? Colors.white : AppColors.slate500),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: AppTypography.bodySmall.copyWith(
                    color: secili ? Colors.white : AppColors.slate600,
                    fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Onay kartı ───
class _OnayKart extends StatelessWidget {
  final OnayBekleyen veri;
  final bool islemde;
  final VoidCallback onOnayla;
  final VoidCallback onReddet;

  const _OnayKart({
    required this.veri,
    required this.islemde,
    required this.onOnayla,
    required this.onReddet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Masraf fişinde fiş fotoğrafı önizlemesi; diğerlerinde tür ikonu.
              if (veri.tip == OnayBelgeTip.masraf)
                MasrafReceiptImage(masrafId: veri.id, size: 44, borderRadius: 12)
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: veri.tip.renk.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(veri.tip.ikon, color: veri.tip.renk, size: 20),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(veri.clientTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h3.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${veri.tip.etiket} · ${veri.trCodeAd}',
                        style: AppTypography.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(Formatters.currency(veri.netTotal),
                  style: AppTypography.h3.copyWith(
                      fontSize: 14, color: AppColors.slate900)),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 0.5, color: AppColors.slate200),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 14, color: AppColors.slate400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${veri.createdBy} · ${Formatters.relativeTime(veri.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
              ),
              Text(veri.belgeNo,
                  style: AppTypography.caption
                      .copyWith(fontSize: 11, color: AppColors.slate500)),
            ],
          ),
          const SizedBox(height: 12),
          // Aksiyon butonları
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: islemde ? null : onReddet,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reddet'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.negative,
                    side: const BorderSide(color: AppColors.negative),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: islemde ? null : onOnayla,
                  icon: islemde
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Onayla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.positive,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Yükleniyor iskeleti ───
class _OnaySkeleton extends StatelessWidget {
  const _OnaySkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.slate200,
      highlightColor: AppColors.slate100,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
