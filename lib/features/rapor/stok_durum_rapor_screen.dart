import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../core/utils/pdf_onizleme_screen.dart';
import '../malzeme/malzeme_model.dart' show MalzemeTur;
import 'rapor_model.dart';
import 'rapor_service.dart';
import 'rapor_widgets.dart';

// Stok durum raporu — malzeme ad/açıklama + fiili ve gerçek (kullanılabilir) stok.
class StokDurumRaporScreen extends StatefulWidget {
  const StokDurumRaporScreen({super.key});

  @override
  State<StokDurumRaporScreen> createState() => _StokDurumRaporScreenState();
}

class _StokDurumRaporScreenState extends State<StokDurumRaporScreen> {
  List<StokRapor> _liste = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  Timer? _debounce;
  int? _tur; // ITEMS.CARDTYPE
  String? _stokDurumu; // 'var' | 'yok'

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final sonuc = await raporService.getStok(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        tur: _tur,
        stokDurumu: _stokDurumu,
      );
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value != _searchQuery) {
        _searchQuery = value;
        _load();
      }
    });
  }

  void _setTur(int? t) {
    setState(() => _tur = t);
    _load();
  }

  void _setStokDurumu(String? s) {
    setState(() => _stokDurumu = s);
    _load();
  }

  Future<void> _pdfAc() async {
    final filtre = <String>[
      if (_searchQuery.isNotEmpty) 'Arama: $_searchQuery',
      if (_tur != null)
        MalzemeTur.values
            .firstWhere((m) => m.cardType == _tur,
                orElse: () => MalzemeTur.ticariMal)
            .adi,
      if (_stokDurumu == 'var')
        'Stoğu olanlar'
      else if (_stokDurumu == 'yok')
        'Stoğu olmayanlar',
    ].join(' · ');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfOnizlemeScreen(
          baslik: 'Stok Durum Raporu',
          pdfOlustur: () => buildTabloRaporPdf(
            baslik: 'Stok Durum Raporu',
            altBilgi: filtre,
            kolonlar: const [
              'Kod',
              'Malzeme',
              'Tür',
              'Birim',
              'Fiili',
              'Gerçek',
            ],
            sagKolonlar: const {4, 5},
            genislikler: const [1.5, 3.5, 1.5, 1, 1.2, 1.2],
            satirlar: _liste
                .map((s) => [
                      s.kod,
                      [s.ad, s.aciklama].where((x) => x.isNotEmpty).join(' — '),
                      s.tur,
                      s.birim,
                      _sayi(s.fiiliStok),
                      _sayi(s.gercekStok),
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
        title: const Text('Stok Durum'),
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
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: RaporSearchBar(
                  hint: 'Malzeme ara — ad, kod...',
                  onChanged: _onSearchChanged,
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  children: [
                    RaporChip(
                        label: 'Tüm türler',
                        selected: _tur == null,
                        onTap: () => _setTur(null)),
                    for (final t in MalzemeTur.values)
                      RaporChip(
                          label: t.adi,
                          selected: _tur == t.cardType,
                          onTap: () => _setTur(t.cardType)),
                    Container(
                        width: 1,
                        height: 22,
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 11),
                        color: AppColors.slate200),
                    RaporChip(
                        label: 'Stoğu var',
                        selected: _stokDurumu == 'var',
                        onTap: () => _setStokDurumu(
                            _stokDurumu == 'var' ? null : 'var')),
                    RaporChip(
                        label: 'Stoğu yok',
                        selected: _stokDurumu == 'yok',
                        aktifRenk: AppColors.negative,
                        onTap: () => _setStokDurumu(
                            _stokDurumu == 'yok' ? null : 'yok')),
                  ],
                ),
              ),
            ],
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
    if (_isLoading) return const RaporLoading();
    if (_error != null && _liste.isEmpty) {
      return RaporError(mesaj: _error!, onRetry: _load);
    }
    if (_liste.isEmpty) return const RaporEmpty();
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _liste.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _StokCard(rapor: _liste[i]),
    );
  }
}

String _sayi(double v) {
  // Tam sayıysa ondalık gösterme
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

class _StokCard extends StatelessWidget {
  final StokRapor rapor;
  const _StokCard({required this.rapor});

  @override
  Widget build(BuildContext context) {
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
                    Text(rapor.ad,
                        style: AppTypography.h3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (rapor.aciklama.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(rapor.aciklama,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 2),
                    Text(
                        [rapor.kod, if (rapor.tur.isNotEmpty) rapor.tur]
                            .join(' · '),
                        style: AppTypography.caption),
                  ],
                ),
              ),
              if (rapor.stokYok)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.negativeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Stok yok',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.negative)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _miniStok('Fiili stok', rapor.fiiliStok, rapor.birim,
                  AppColors.slate700),
              _miniStok('Gerçek stok', rapor.gercekStok, rapor.birim,
                  AppColors.accentDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStok(String etiket, double deger, String birim, Color renk) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket, style: AppTypography.caption),
          const SizedBox(height: 2),
          Text('${_sayi(deger)} $birim',
              style: AppTypography.bodySmall
                  .copyWith(color: renk, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
