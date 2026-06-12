import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../auth/auth_service.dart';
import '../dashboard/bugun_tahsilatlar_screen.dart';
import 'tahsilat_model.dart';
import 'tahsilat_taslak_service.dart';
import 'tahsilat_giris_screen.dart';

// Satışçının kestiği tahsilat/ödeme fişlerinin listesi.
// Onay durumuna göre filtre + kaydır-sil + düzenle (onaya gönderilmemiş olanlar).
class TahsilatListeScreen extends StatefulWidget {
  const TahsilatListeScreen({super.key});

  @override
  State<TahsilatListeScreen> createState() => _TahsilatListeScreenState();
}

// Onay durumuna göre üst sekmeler.
enum _Filtre { tumu, bekleyen, onayli, reddedilen }

extension _FiltreX on _Filtre {
  String get etiket => switch (this) {
        _Filtre.tumu => 'Tümü',
        _Filtre.bekleyen => 'Bekleyen',
        _Filtre.onayli => 'Onaylı',
        _Filtre.reddedilen => 'Reddedilen',
      };

  bool eslesir(TahsilatTaslakModel t) => switch (this) {
        _Filtre.tumu => true,
        _Filtre.bekleyen => t.isOnayBekliyor,
        _Filtre.onayli => t.isOnaylandi,
        _Filtre.reddedilen => t.isReddedildi,
      };
}

class _TahsilatListeScreenState extends State<TahsilatListeScreen> {
  List<TahsilatTaslakModel> _liste = [];
  bool _yukleniyor = true;
  String? _hata;
  _Filtre _filtre = _Filtre.tumu;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final liste = await tahsilatTaslakService.getTaslaklar(limit: 100);
      if (!mounted) return;
      setState(() {
        _liste = liste;
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

  Future<void> _yeni() async {
    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TahsilatGirisScreen()),
    );
    if (sonuc == true) _yukle();
  }

  Future<void> _duzenle(TahsilatTaslakModel t) async {
    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TahsilatGirisScreen(duzenlenecek: t)),
    );
    if (sonuc == true) _yukle();
  }

  // Onaylı taslağı LOGO'ya aktar (şu an backend'de stub — "henüz aktif değil" döner).
  Future<void> _aktar(TahsilatTaslakModel t) async {
    try {
      final ficheId = await tahsilatTaslakService.transferTaslak(t.id!);
      if (!mounted) return;
      _bildir('LOGO\'ya aktarıldı (#$ficheId)', AppColors.positive);
      _yukle();
    } catch (e) {
      if (!mounted) return;
      _bildir('Aktarım başarısız: $e', AppColors.negative);
      _yukle();
    }
  }

  Future<void> _sil(TahsilatTaslakModel t) async {
    try {
      await tahsilatTaslakService.deleteTaslak(t.id!);
      if (!mounted) return;
      setState(() => _liste.removeWhere((x) => x.id == t.id));
      _bildir('Tahsilat fişi silindi', AppColors.slate600);
    } catch (e) {
      if (!mounted) return;
      _bildir(e.toString(), AppColors.negative);
      _yukle(); // silinemezse listeyi geri getir
    }
  }

  void _bildir(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: renk),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gosterilen = _liste.where(_filtre.eslesir).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleTextStyle: AppTypography.h2,
        foregroundColor: AppColors.slate900,
        title: const Text('Tahsilat Fişleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_rounded),
            tooltip: 'LOGO\'daki tahsilatlar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BugunTahsilatlarScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FiltreBari(
            secili: _filtre,
            onSec: (f) => setState(() => _filtre = f),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _yeni,
        backgroundColor: AppColors.positive,
        icon: const Icon(Icons.add_rounded),
        label: Text('Yeni', style: AppTypography.button),
      ),
      body: RefreshIndicator(
        onRefresh: _yukle,
        child: _govde(gosterilen),
      ),
    );
  }

  Widget _govde(List<TahsilatTaslakModel> gosterilen) {
    if (_yukleniyor) return const _Iskelet();
    if (_hata != null) {
      return _DurumWidget(
        ikon: Icons.cloud_off_rounded,
        baslik: 'Liste yüklenemedi',
        aciklama: _hata!,
        aksiyon: TextButton(onPressed: _yukle, child: const Text('Tekrar dene')),
      );
    }
    if (gosterilen.isEmpty) {
      return _DurumWidget(
        ikon: Icons.payments_outlined,
        baslik: _filtre == _Filtre.tumu
            ? 'Henüz tahsilat fişi yok'
            : '${_filtre.etiket} fiş yok',
        aciklama: 'Yeni tahsilat eklemek için sağ alttaki + butonunu kullan.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
      itemCount: gosterilen.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _TahsilatKart(
        tahsilat: gosterilen[i],
        onDuzenle: () => _duzenle(gosterilen[i]),
        onSil: () => _sil(gosterilen[i]),
        onAktar: () => _aktar(gosterilen[i]),
      ),
    );
  }
}

// ─── Filtre barı ─────────────────────────────────────────────────────────────
class _FiltreBari extends StatelessWidget {
  final _Filtre secili;
  final ValueChanged<_Filtre> onSec;
  const _FiltreBari({required this.secili, required this.onSec});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: _Filtre.values.map((f) {
          final aktif = f == secili;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onSec(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: aktif ? AppColors.primary : AppColors.slate100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f.etiket,
                  style: AppTypography.caption.copyWith(
                    color: aktif ? Colors.white : AppColors.slate500,
                    fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Tahsilat kartı ──────────────────────────────────────────────────────────
class _TahsilatKart extends StatelessWidget {
  final TahsilatTaslakModel tahsilat;
  final VoidCallback onDuzenle;
  final VoidCallback onSil;
  final VoidCallback onAktar;
  const _TahsilatKart({
    required this.tahsilat,
    required this.onDuzenle,
    required this.onSil,
    required this.onAktar,
  });

  // Aktarılmış kayıt silinemez/düzenlenemez; onaylanmış düzenlenemez.
  bool get _silinebilir => tahsilat.status != 'Transferred';
  bool get _duzenlenebilir =>
      tahsilat.status != 'Transferred' && !tahsilat.isOnaylandi;
  // Aktar/Tekrar Dene yalnızca patron onayı geçmiş, henüz aktarılmamış taslakta.
  bool get _aktarGoster =>
      tahsilat.isOnaylandi &&
      tahsilat.status != 'Transferred' &&
      authService.perms.canTransferBelge;

  @override
  Widget build(BuildContext context) {
    final tur = tahsilat.tur;
    final tutarRenk = tur.isOdeme ? AppColors.negative : AppColors.positive;

    final kart = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _duzenlenebilir ? onDuzenle : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tutarRenk.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tur.ikon, color: tutarRenk, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tahsilat.clientTitle,
                          style: AppTypography.body
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tur.adi} · ${_tarih(tahsilat.date)}',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tur.isOdeme ? '-' : '+'}${Formatters.currency(tahsilat.amount)}',
                        style: AppTypography.body.copyWith(
                          color: tutarRenk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _DurumRozet(tahsilat: tahsilat),
                    ],
                  ),
                ],
              ),
              // Reddedilme gerekçesi
              if (tahsilat.isReddedildi) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.negativeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ret gerekçesi: ${(tahsilat.rejectReason?.trim().isNotEmpty ?? false) ? tahsilat.rejectReason : 'Gerekçe belirtilmedi'}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.negative),
                  ),
                ),
              ],
              // LOGO'ya aktar / tekrar dene (onaylı taslak)
              if (_aktarGoster) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAktar,
                    icon: Icon(
                      tahsilat.status == 'Failed'
                          ? Icons.refresh_rounded
                          : Icons.cloud_upload_rounded,
                      size: 18,
                    ),
                    label: Text(
                      tahsilat.status == 'Failed'
                          ? 'Tekrar Dene'
                          : "LOGO'ya Aktar",
                      style: AppTypography.button
                          .copyWith(color: AppColors.positive),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.positive,
                      side: const BorderSide(color: AppColors.positive),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!_silinebilir) return kart;
    return Dismissible(
      key: ValueKey(tahsilat.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _silOnayi(context),
      onDismissed: (_) => onSil(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.negative,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: kart,
    );
  }

  Future<bool> _silOnayi(BuildContext context) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tahsilat fişini sil'),
        content: Text(
            '${tahsilat.clientTitle} için ${Formatters.currency(tahsilat.amount)} tutarındaki fiş silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.negative),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    return onay ?? false;
  }

  String _tarih(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ─── Durum rozeti ────────────────────────────────────────────────────────────
class _DurumRozet extends StatelessWidget {
  final TahsilatTaslakModel tahsilat;
  const _DurumRozet({required this.tahsilat});

  ({String metin, Color renk, Color bg}) get _stil {
    if (tahsilat.status == 'Transferred') {
      return (metin: "LOGO'da", renk: AppColors.primary, bg: AppColors.slate100);
    }
    if (tahsilat.status == 'Failed') {
      return (
        metin: 'Aktarım Hatası',
        renk: AppColors.negative,
        bg: AppColors.negativeBg
      );
    }
    if (tahsilat.isOnaylandi) {
      return (metin: 'Onaylandı', renk: AppColors.positive, bg: AppColors.positiveBg);
    }
    if (tahsilat.isReddedildi) {
      return (metin: 'Reddedildi', renk: AppColors.negative, bg: AppColors.negativeBg);
    }
    return (metin: 'Onay Bekliyor', renk: AppColors.warning, bg: AppColors.warningBg);
  }

  @override
  Widget build(BuildContext context) {
    final s = _stil;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(s.metin,
          style: AppTypography.caption
              .copyWith(color: s.renk, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Boş / hata durumu ───────────────────────────────────────────────────────
class _DurumWidget extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String aciklama;
  final Widget? aksiyon;
  const _DurumWidget({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    this.aksiyon,
  });

  @override
  Widget build(BuildContext context) {
    // RefreshIndicator'ın çalışması için kaydırılabilir olmalı.
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: 80),
      children: [
        Icon(ikon, size: 56, color: AppColors.slate300),
        const SizedBox(height: AppSpacing.md),
        Text(baslik,
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: AppColors.slate600)),
        const SizedBox(height: AppSpacing.sm),
        Text(aciklama,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.slate400)),
        if (aksiyon != null) ...[
          const SizedBox(height: AppSpacing.md),
          Center(child: aksiyon!),
        ],
      ],
    );
  }
}

// ─── Yükleme iskeleti (shimmer) ──────────────────────────────────────────────
class _Iskelet extends StatelessWidget {
  const _Iskelet();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.slate200,
      highlightColor: AppColors.slate100,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
