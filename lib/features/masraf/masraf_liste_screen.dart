import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/fade_slide_in.dart';
import 'masraf_giris_screen.dart';
import 'masraf_model.dart';
import 'masraf_receipt_image.dart';
import 'masraf_service.dart';

// Masraf listesi — satışçı kendi masraflarını ve ödeme durumunu, patron/muhasebe
// herkesinkini görür. Onaylı + ödenmemiş masrafı patron "Ödendi" işaretler.
class MasrafListeScreen extends StatefulWidget {
  const MasrafListeScreen({super.key});

  @override
  State<MasrafListeScreen> createState() => _MasrafListeScreenState();
}

enum _Filtre {
  tumu('Tümü', null, null),
  bekleyen('Bekleyen', 'Pending', null),
  onayli('Onaylı', 'Approved', null),
  reddedilen('Reddedilen', 'Rejected', null),
  odendi('Ödendi', null, 'Paid');

  const _Filtre(this.etiket, this.approvalStatus, this.paymentStatus);
  final String etiket;
  final String? approvalStatus;
  final String? paymentStatus;
}

class _MasrafListeScreenState extends State<MasrafListeScreen> {
  List<MasrafModel>? _liste;
  String? _hata;
  bool _yukleniyor = true;
  _Filtre _filtre = _Filtre.tumu;
  final Set<int> _islemde = {};

  bool get _patron => authService.perms.canApproveBelge;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final l = await masrafService.getMasraflar(
        approvalStatus: _filtre.approvalStatus,
        paymentStatus: _filtre.paymentStatus,
      );
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

  void _filtreDegistir(_Filtre f) {
    if (_filtre == f) return;
    setState(() => _filtre = f);
    _yukle();
  }

  Future<void> _yeniMasraf() async {
    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const MasrafGirisScreen()),
    );
    if (sonuc == true) _yukle();
  }

  Future<void> _duzenle(MasrafModel m) async {
    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MasrafGirisScreen(duzenlenecek: m)),
    );
    if (sonuc == true) _yukle();
  }

  Future<void> _odendiYap(MasrafModel m) async {
    final yontem = await _odemeYontemiSor();
    if (yontem == null) return; // iptal
    setState(() => _islemde.add(m.id!));
    try {
      await masrafService.markOdendi(m.id!, method: yontem.isEmpty ? null : yontem);
      if (!mounted) return;
      _bildir('Masraf ödendi olarak işaretlendi', AppColors.positive);
      _yukle();
    } catch (e) {
      if (!mounted) return;
      _bildir(e.toString(), AppColors.negative);
    } finally {
      if (mounted) setState(() => _islemde.remove(m.id));
    }
  }

  // Ödeme yöntemi sor (boş geçilebilir, iptal → null).
  Future<String?> _odemeYontemiSor() async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text('Ödeme Yöntemi', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            for (final y in const ['Nakit', 'Havale', 'EFT'])
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_rounded,
                    color: AppColors.positive),
                title: Text(y, style: AppTypography.body),
                onTap: () => Navigator.pop(ctx, y),
              ),
            ListTile(
              leading:
                  const Icon(Icons.check_rounded, color: AppColors.slate500),
              title: Text('Belirtmeden işaretle', style: AppTypography.body),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Masraflar'),
        titleTextStyle:
            AppTypography.h1.copyWith(color: AppColors.slate900, fontSize: 22),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: authService.perms.canCreateBelge
          ? FloatingActionButton.extended(
              onPressed: _yeniMasraf,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
              label: Text('Masraf Ekle',
                  style: AppTypography.button.copyWith(color: Colors.white)),
            )
          : null,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _Filtre.values
              .map((f) => _FiltreCip(
                    label: f.etiket,
                    secili: _filtre == f,
                    onTap: () => _filtreDegistir(f),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_yukleniyor) return const _MasrafSkeleton();
    if (_hata != null) return _buildHata();
    final liste = _liste ?? const [];
    if (liste.isEmpty) return _buildBos();
    return RefreshIndicator(
      onRefresh: _yukle,
      color: AppColors.accent,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
        itemCount: liste.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) => FadeSlideIn(
          delay: Duration(milliseconds: (i * 50).clamp(0, 300)),
          child: _MasrafKart(
            veri: liste[i],
            patron: _patron,
            islemde: _islemde.contains(liste[i].id),
            onDuzenle: () => _duzenle(liste[i]),
            onOdendi: () => _odendiYap(liste[i]),
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
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.primary, size: 42),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Masraf yok',
                      style: AppTypography.h2.copyWith(fontSize: 18)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Bu filtrede gösterilecek masraf bulunmuyor.',
                      textAlign: TextAlign.center,
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
  final bool secili;
  final VoidCallback onTap;
  const _FiltreCip(
      {required this.label, required this.secili, required this.onTap});

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
          child: Text(label,
              style: AppTypography.bodySmall.copyWith(
                color: secili ? Colors.white : AppColors.slate600,
                fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
              )),
        ),
      ),
    );
  }
}

// ─── Masraf kartı ───
class _MasrafKart extends StatelessWidget {
  final MasrafModel veri;
  final bool patron;
  final bool islemde;
  final VoidCallback onDuzenle;
  final VoidCallback onOdendi;

  const _MasrafKart({
    required this.veri,
    required this.patron,
    required this.islemde,
    required this.onDuzenle,
    required this.onOdendi,
  });

  // Satışçı kendi bekleyen/reddedilen masrafını (henüz ödenmemiş) düzenleyebilir.
  bool get _duzenlenebilir => !veri.isOdendi && !veri.isOnaylandi;
  // Patron onaylı + ödenmemiş masrafı "Ödendi" işaretleyebilir.
  bool get _odenebilir => patron && veri.isOnaylandi && !veri.isOdendi;

  @override
  Widget build(BuildContext context) {
    final k = veri.kategori;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fiş fotoğrafı önizlemesi (yoksa kategori ikonu)
              if (veri.hasReceipt && veri.id != null)
                MasrafReceiptImage(masrafId: veri.id!, size: 56)
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: k.renk.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(k.ikon, color: k.renk, size: 24),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(k.ikon, size: 14, color: k.renk),
                        const SizedBox(width: 4),
                        Text(k.adi,
                            style: AppTypography.h3.copyWith(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${veri.createdBy} · ${veri.createdAt != null ? Formatters.relativeTime(veri.createdAt!) : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                    if (veri.aciklama != null && veri.aciklama!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(veri.aciklama!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.slate500)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(Formatters.currency(veri.amount),
                  style: AppTypography.h3
                      .copyWith(fontSize: 15, color: AppColors.slate900)),
            ],
          ),
          const SizedBox(height: 10),
          // Durum rozetleri
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DurumRozeti.onay(veri),
              _DurumRozeti.odeme(veri),
              if (veri.isReddedildi &&
                  veri.rejectReason != null &&
                  veri.rejectReason!.isNotEmpty)
                _RedGerekce(gerekce: veri.rejectReason!),
            ],
          ),
          if (_duzenlenebilir || _odenebilir) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (_duzenlenebilir)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDuzenle,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Düzenle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate600,
                        side: const BorderSide(color: AppColors.slate300),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (_duzenlenebilir && _odenebilir)
                  const SizedBox(width: AppSpacing.sm),
                if (_odenebilir)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: islemde ? null : onOdendi,
                      icon: islemde
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.payments_rounded, size: 16),
                      label: const Text('Ödendi'),
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
        ],
      ),
    );
  }
}

// ─── Durum rozeti (onay / ödeme) ───
class _DurumRozeti extends StatelessWidget {
  final String metin;
  final IconData ikon;
  final Color renk;
  const _DurumRozeti(
      {required this.metin, required this.ikon, required this.renk});

  factory _DurumRozeti.onay(MasrafModel m) {
    if (m.isOnaylandi) {
      return const _DurumRozeti(
          metin: 'Onaylandı',
          ikon: Icons.check_circle_rounded,
          renk: AppColors.positive);
    }
    if (m.isReddedildi) {
      return const _DurumRozeti(
          metin: 'Reddedildi',
          ikon: Icons.cancel_rounded,
          renk: AppColors.negative);
    }
    return const _DurumRozeti(
        metin: 'Onay Bekliyor',
        ikon: Icons.hourglass_top_rounded,
        renk: AppColors.warning);
  }

  factory _DurumRozeti.odeme(MasrafModel m) {
    if (m.isOdendi) {
      return const _DurumRozeti(
          metin: 'Ödendi',
          ikon: Icons.payments_rounded,
          renk: AppColors.positive);
    }
    return const _DurumRozeti(
        metin: 'Ödenmedi',
        ikon: Icons.schedule_rounded,
        renk: AppColors.slate500);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 13, color: renk),
          const SizedBox(width: 4),
          Text(metin,
              style: AppTypography.caption
                  .copyWith(color: renk, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Red gerekçesi rozeti ───
class _RedGerekce extends StatelessWidget {
  final String gerekce;
  const _RedGerekce({required this.gerekce});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.negative.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Gerekçe: $gerekce',
          style: AppTypography.caption.copyWith(color: AppColors.negative)),
    );
  }
}

// ─── Yükleniyor iskeleti ───
class _MasrafSkeleton extends StatelessWidget {
  const _MasrafSkeleton();

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
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
