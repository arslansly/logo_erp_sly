import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../core/utils/pdf_onizleme_screen.dart';
import 'rapor_model.dart';
import 'rapor_service.dart';
import 'rapor_widgets.dart';

// Vade raporu — vadesi geçmiş bakiyesi olan cariler, yaşlandırma kovalarıyla.
class VadeRaporScreen extends StatefulWidget {
  const VadeRaporScreen({super.key});

  @override
  State<VadeRaporScreen> createState() => _VadeRaporScreenState();
}

class _VadeRaporScreenState extends State<VadeRaporScreen> {
  List<VadeRapor> _liste = [];
  bool _isLoading = false;
  String? _error;
  int? _minGun;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final sonuc = await raporService.getVade(minGun: _minGun);
      if (!mounted) return;
      setState(() {
        _liste = sonuc;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setMinGun(int? g) {
    setState(() => _minGun = g);
    _load();
  }

  double get _toplamVadeGecen =>
      _liste.fold(0.0, (t, v) => t + v.toplamVadesiGecen);

  Future<void> _pdfAc() async {
    final filtre = _minGun == null ? 'Tüm gecikmeler' : '$_minGun+ gün gecikme';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfOnizlemeScreen(
          baslik: 'Vade Raporu',
          pdfOlustur: () => buildTabloRaporPdf(
            baslik: 'Vade Raporu',
            altBilgi: filtre,
            ozetler: [
              ('Vadesi Geçen Cari', '${_liste.length}'),
              ('Toplam Vadesi Geçen', Formatters.currency(_toplamVadeGecen)),
            ],
            kolonlar: const [
              'Kod',
              'Ünvan',
              'Şehir',
              'En Eski (gün)',
              'Vade Adedi',
              'Vadesi Geçen',
            ],
            sagKolonlar: const {3, 4, 5},
            genislikler: const [1.3, 3, 1.5, 1.3, 1.2, 1.7],
            satirlar: _liste
                .map((v) => [
                      v.code,
                      v.title,
                      v.city,
                      '${v.enEskiGunFarki}',
                      '${v.vadeSayisi}',
                      Formatters.currency(v.toplamVadesiGecen),
                    ])
                .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vade Raporu'),
        titleTextStyle:
            AppTypography.h1.copyWith(color: AppColors.slate900, fontSize: 22),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'PDF olarak paylaş',
            onPressed: _liste.isEmpty ? null : _pdfAc,
            icon: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.slate700),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                RaporChip(
                    label: 'Tümü',
                    selected: _minGun == null,
                    onTap: () => _setMinGun(null)),
                RaporChip(
                    label: '30+ gün',
                    selected: _minGun == 30,
                    aktifRenk: AppColors.warning,
                    onTap: () => _setMinGun(30)),
                RaporChip(
                    label: '60+ gün',
                    selected: _minGun == 60,
                    aktifRenk: AppColors.warning,
                    onTap: () => _setMinGun(60)),
                RaporChip(
                    label: '90+ gün',
                    selected: _minGun == 90,
                    aktifRenk: AppColors.negative,
                    onTap: () => _setMinGun(90)),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const RaporLoading(itemHeight: 96);
    if (_error != null && _liste.isEmpty) {
      return RaporError(mesaj: _error!, onRetry: _load);
    }
    if (_liste.isEmpty) {
      return const RaporEmpty(
          mesaj: 'Vadesi geçen cari yok', ikon: Icons.check_circle_outline);
    }
    return Column(
      children: [
        _ozetBar(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _liste.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _VadeCard(rapor: _liste[i]),
          ),
        ),
      ],
    );
  }

  Widget _ozetBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.negativeBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.negative),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('${_liste.length} cari · toplam vadesi geçen',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.slate700)),
          ),
          Text(Formatters.currency(_toplamVadeGecen),
              style: AppTypography.h3.copyWith(color: AppColors.negative)),
        ],
      ),
    );
  }
}

class _VadeCard extends StatelessWidget {
  final VadeRapor rapor;
  const _VadeCard({required this.rapor});

  @override
  Widget build(BuildContext context) {
    final kritik = rapor.enEskiGunFarki > 90;
    final rozetRenk = kritik ? AppColors.negative : AppColors.warning;
    final rozetBg = kritik ? AppColors.negativeBg : AppColors.warningBg;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rapor.title,
                        style: AppTypography.h3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                        [rapor.code, if (rapor.city.isNotEmpty) rapor.city]
                            .join(' · '),
                        style: AppTypography.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(Formatters.currency(rapor.toplamVadesiGecen),
                  style: AppTypography.h3.copyWith(color: AppColors.negative)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rozetBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${rapor.enEskiGunFarki} gün gecikme',
                    style: AppTypography.caption
                        .copyWith(color: rozetRenk, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${rapor.vadeSayisi} vade', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _agingBar(),
        ],
      ),
    );
  }

  Widget _agingBar() {
    Widget kova(String etiket, double tutar, Color renk) {
      if (tutar <= 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiket, style: AppTypography.caption.copyWith(fontSize: 10)),
            Text(Formatters.currencyCompact(tutar),
                style: AppTypography.caption
                    .copyWith(color: renk, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Wrap(
      children: [
        kova('0-30', rapor.vadesi_0_30, AppColors.warning),
        kova('31-60', rapor.vadesi_31_60, AppColors.warning),
        kova('61-90', rapor.vadesi_61_90, AppColors.negative),
        kova('90+', rapor.vadesi_90Plus, AppColors.negative),
      ],
    );
  }
}
