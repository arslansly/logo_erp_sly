import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'malzeme_hareket_screen.dart';
import 'malzeme_image.dart';
import 'malzeme_model.dart';
import 'malzeme_service.dart';

class MalzemeDetayScreen extends StatefulWidget {
  final int malzemeId;
  final Malzeme? initialMalzeme;

  const MalzemeDetayScreen({
    super.key,
    required this.malzemeId,
    this.initialMalzeme,
  });

  @override
  State<MalzemeDetayScreen> createState() => _MalzemeDetayScreenState();
}

class _MalzemeDetayScreenState extends State<MalzemeDetayScreen> {
  MalzemeDetay? _detay;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final detay = await malzemeService.getMalzemeDetay(widget.malzemeId);
      if (!mounted) return;
      setState(() {
        _detay = detay;
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
    final title =
        _detay?.ad ?? widget.initialMalzeme?.ad ?? 'Malzeme Detayı';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title,
            style: AppTypography.h2.copyWith(color: AppColors.slate900)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: AppColors.slate700),
        actions: [
          IconButton(
            tooltip: 'Ekstre',
            icon: const Icon(Icons.receipt_long_rounded,
                color: AppColors.slate700),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MalzemeHareketScreen(
                  malzemeId: widget.malzemeId,
                  malzemeAdi: title,
                  birim: _detay?.birim ?? widget.initialMalzeme?.birim ?? '',
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_detay == null) return const SizedBox();
    return _buildContent(_detay!);
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
          3,
          (_) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(16),
                ),
              )),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.negativeBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.negative, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Yüklenemedi', style: AppTypography.h2.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.slate600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(MalzemeDetay d) {
    final hasFiyat = d.satinalmaFiyati > 0 ||
        d.satisFiyati > 0 ||
        d.sonAlisFiyati > 0 ||
        d.sonSatisFiyati > 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroCard(detay: d),
        const SizedBox(height: 16),
        _StokOzetCard(detay: d),
        if (hasFiyat) ...[
          const SizedBox(height: 16),
          _FiyatSection(detay: d),
        ],
        if (d.ambarStoklar.isNotEmpty) ...[
          const SizedBox(height: 16),
          _AmbarlarSection(ambarlar: d.ambarStoklar, birim: d.birim),
        ],
        const SizedBox(height: 16),
        _BilgiSection(detay: d),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Hero card ──────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final MalzemeDetay detay;
  const _HeroCard({required this.detay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          MalzemeImage(
            malzemeId: detay.id,
            size: 64,
            borderRadius: 14,
            fallbackBg: Colors.white.withValues(alpha: 0.2),
            fallbackFg: Colors.white,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detay.ad,
                  style: AppTypography.h2.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  detay.kod,
                  style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
          if (detay.stokYok)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.negative,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Stok Yok',
                style: AppTypography.caption.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stok özet kartı ────────────────────────────────────────────────────────

class _StokOzetCard extends StatelessWidget {
  final MalzemeDetay detay;
  const _StokOzetCard({required this.detay});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('tr_TR');
    final rezerveli = detay.rezerveli;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stok Durumu',
              style:
                  AppTypography.h3.copyWith(color: AppColors.slate700)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StokSayac(
                  label: 'Fiili Stok',
                  deger: fmt.format(detay.fiiliStok),
                  birim: detay.birim,
                  renk: detay.stokYok
                      ? AppColors.negative
                      : AppColors.positive,
                  bgRenk: detay.stokYok
                      ? AppColors.negativeBg
                      : AppColors.positiveBg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StokSayac(
                  label: 'Gerçek Stok',
                  deger: fmt.format(detay.gercekStok),
                  birim: detay.birim,
                  renk: detay.gercekStok <= 0
                      ? AppColors.negative
                      : AppColors.accent,
                  bgRenk: detay.gercekStok <= 0
                      ? AppColors.negativeBg
                      : AppColors.accentLight.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          if (rezerveli > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${fmt.format(rezerveli)} ${detay.birim} rezerveli',
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StokSayac extends StatelessWidget {
  final String label;
  final String deger;
  final String birim;
  final Color renk;
  final Color bgRenk;

  const _StokSayac({
    required this.label,
    required this.deger,
    required this.birim,
    required this.renk,
    required this.bgRenk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgRenk,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.caption.copyWith(color: renk)),
          const SizedBox(height: 6),
          Text(deger,
              style: AppTypography.h2
                  .copyWith(color: renk, fontSize: 20)),
          Text(birim,
              style: AppTypography.caption
                  .copyWith(color: renk.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

// ── Ambarlar section ───────────────────────────────────────────────────────

class _AmbarlarSection extends StatelessWidget {
  final List<AmbarStok> ambarlar;
  final String birim;
  const _AmbarlarSection({required this.ambarlar, required this.birim});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('tr_TR');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text('Ambar Dökümü',
                style: AppTypography.h3.copyWith(color: AppColors.slate700)),
          ),
          const Divider(height: 1, color: AppColors.slate200),
          ...ambarlar.map((a) => _AmbarSatir(ambar: a, birim: birim, fmt: fmt)),
        ],
      ),
    );
  }
}

class _AmbarSatir extends StatelessWidget {
  final AmbarStok ambar;
  final String birim;
  final NumberFormat fmt;
  const _AmbarSatir(
      {required this.ambar, required this.birim, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${ambar.ambarNo}',
                style: AppTypography.h3
                    .copyWith(color: AppColors.slate600, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ambar.ambarAdi.isEmpty ? 'Ambar ${ambar.ambarNo}' : ambar.ambarAdi,
              style: AppTypography.body.copyWith(color: AppColors.slate800),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${fmt.format(ambar.fiiliStok)} $birim',
                style: AppTypography.h3.copyWith(
                    color: ambar.fiiliStok <= 0
                        ? AppColors.negative
                        : AppColors.slate800,
                    fontSize: 14),
              ),
              if (ambar.fiiliStok != ambar.gercekStok)
                Text(
                  'Gerçek: ${fmt.format(ambar.gercekStok)}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.slate500, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Fiyat section ──────────────────────────────────────────────────────────

class _FiyatSection extends StatelessWidget {
  final MalzemeDetay detay;
  const _FiyatSection({required this.detay});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('tr_TR');

    String f(double v) => fmt.format(v);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text('Fiyatlar',
                style: AppTypography.h3.copyWith(color: AppColors.slate700)),
          ),
          const Divider(height: 1, color: AppColors.slate200),
          if (detay.satinalmaFiyati > 0)
            _FiyatSatir(
              label: 'Satınalma (Tanımlı)',
              ikon: Icons.shopping_cart_outlined,
              deger: '${f(detay.satinalmaFiyati)} ${detay.satinalmaDoviz}',
              renk: AppColors.slate800,
            ),
          if (detay.satisFiyati > 0) ...[
            const Divider(height: 1, color: AppColors.slate200, indent: 52),
            _FiyatSatir(
              label: 'Satış (Tanımlı)',
              ikon: Icons.sell_outlined,
              deger: '${f(detay.satisFiyati)} ${detay.satisDoviz}',
              renk: AppColors.slate800,
            ),
          ],
          if (detay.sonAlisFiyati > 0) ...[
            const Divider(height: 1, color: AppColors.slate200, indent: 52),
            _FiyatSatir(
              label: 'Son Satınalma',
              ikon: Icons.history_rounded,
              deger: f(detay.sonAlisFiyati),
              renk: AppColors.accent,
            ),
          ],
          if (detay.sonSatisFiyati > 0) ...[
            const Divider(height: 1, color: AppColors.slate200, indent: 52),
            _FiyatSatir(
              label: 'Son Satış',
              ikon: Icons.history_rounded,
              deger: f(detay.sonSatisFiyati),
              renk: AppColors.positive,
            ),
          ],
        ],
      ),
    );
  }
}

class _FiyatSatir extends StatelessWidget {
  final String label;
  final IconData ikon;
  final String deger;
  final Color renk;
  const _FiyatSatir({
    required this.label,
    required this.ikon,
    required this.deger,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(ikon, size: 20, color: AppColors.slate400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AppTypography.body.copyWith(color: AppColors.slate600)),
          ),
          Text(deger,
              style: AppTypography.h3
                  .copyWith(color: renk, fontSize: 15)),
        ],
      ),
    );
  }
}

// ── Bilgi section ──────────────────────────────────────────────────────────

class _BilgiSection extends StatelessWidget {
  final MalzemeDetay detay;
  const _BilgiSection({required this.detay});

  @override
  Widget build(BuildContext context) {
    final ozelKodlar = <(String, String)>[
      if (detay.ozelKod1.isNotEmpty) ('Özel Kod 1', detay.ozelKod1),
      if (detay.ozelKod2.isNotEmpty) ('Özel Kod 2', detay.ozelKod2),
      if (detay.ozelKod3.isNotEmpty) ('Özel Kod 3', detay.ozelKod3),
      if (detay.ozelKod4.isNotEmpty) ('Özel Kod 4', detay.ozelKod4),
      if (detay.ozelKod5.isNotEmpty) ('Özel Kod 5', detay.ozelKod5),
    ];

    final satirlar = <Widget>[
      _InfoSatir(ikon: Icons.qr_code_rounded, label: 'Kod', deger: detay.kod),
      if (detay.tur.isNotEmpty)
        _InfoSatir(
            ikon: Icons.category_outlined, label: 'Türü', deger: detay.tur),
      if (detay.aciklama2.isNotEmpty)
        _InfoSatir(
            ikon: Icons.subject_rounded,
            label: 'Açıklama 2',
            deger: detay.aciklama2),
      if (detay.aciklama3.isNotEmpty)
        _InfoSatir(
            ikon: Icons.subject_rounded,
            label: 'Açıklama 3',
            deger: detay.aciklama3),
      if (detay.grupKodu.isNotEmpty)
        _InfoSatir(
            ikon: Icons.folder_outlined,
            label: 'Grup',
            deger: detay.grupKodu),
      _InfoSatir(
          ikon: Icons.straighten_rounded, label: 'Birim', deger: detay.birim),
      for (final (label, deger) in ozelKodlar)
        _InfoSatir(
            ikon: Icons.label_outline_rounded, label: label, deger: deger),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          for (var i = 0; i < satirlar.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.slate200, indent: 52),
            satirlar[i],
          ],
        ],
      ),
    );
  }
}

class _InfoSatir extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String deger;
  const _InfoSatir(
      {required this.ikon, required this.label, required this.deger});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 20, color: AppColors.slate400),
          const SizedBox(width: 12),
          Text(label,
              style:
                  AppTypography.body.copyWith(color: AppColors.slate600)),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              deger,
              textAlign: TextAlign.end,
              style:
                  AppTypography.body.copyWith(color: AppColors.slate500),
            ),
          ),
        ],
      ),
    );
  }
}
