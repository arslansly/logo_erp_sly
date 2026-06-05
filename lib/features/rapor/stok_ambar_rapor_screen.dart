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

// Ayrıntılı stok raporu — her malzemenin ambar bazlı stok dökümü.
class StokAmbarRaporScreen extends StatefulWidget {
  const StokAmbarRaporScreen({super.key});

  @override
  State<StokAmbarRaporScreen> createState() => _StokAmbarRaporScreenState();
}

class _StokAmbarRaporScreenState extends State<StokAmbarRaporScreen> {
  List<StokAmbarRapor> _liste = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  Timer? _debounce;
  int? _tur;

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
      final sonuc = await raporService.getStokAmbar(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        tur: _tur,
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

  Future<void> _pdfAc() async {
    final filtre = <String>[
      if (_searchQuery.isNotEmpty) 'Arama: $_searchQuery',
      if (_tur != null)
        MalzemeTur.values
            .firstWhere((m) => m.cardType == _tur,
                orElse: () => MalzemeTur.ticariMal)
            .adi,
    ].join(' · ');

    // Her (malzeme, ambar) bir satır
    final satirlar = <List<String>>[];
    for (final m in _liste) {
      for (final a in m.ambarlar) {
        satirlar.add([
          m.kod,
          m.ad,
          a.ambarAdi,
          '${_sayi(a.fiiliStok)} ${m.birim}',
          '${_sayi(a.gercekStok)} ${m.birim}',
        ]);
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfOnizlemeScreen(
          baslik: 'Ayrıntılı Stok Raporu',
          pdfOlustur: () => buildTabloRaporPdf(
            baslik: 'Ayrıntılı Stok Raporu',
            altBilgi: filtre,
            kolonlar: const ['Kod', 'Malzeme', 'Ambar', 'Fiili', 'Gerçek'],
            sagKolonlar: const {3, 4},
            genislikler: const [1.5, 3, 2, 1.4, 1.4],
            satirlar: satirlar,
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
        title: const Text('Ayrıntılı Stok'),
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
    if (_isLoading) return const RaporLoading(itemHeight: 64);
    if (_error != null && _liste.isEmpty) {
      return RaporError(mesaj: _error!, onRetry: _load);
    }
    if (_liste.isEmpty) return const RaporEmpty();
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _liste.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _StokAmbarCard(rapor: _liste[i]),
    );
  }
}

String _sayi(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

class _StokAmbarCard extends StatelessWidget {
  final StokAmbarRapor rapor;
  const _StokAmbarCard({required this.rapor});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          title: Text(rapor.ad,
              style: AppTypography.h3,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
                '${rapor.kod} · ${rapor.ambarlar.length} ambar',
                style: AppTypography.caption),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_sayi(rapor.toplamFiili)} ${rapor.birim}',
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w600)),
              Text('fiili toplam',
                  style: AppTypography.caption.copyWith(fontSize: 10)),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: AppColors.slate100, width: 1)),
              ),
              child: Column(
                children: [
                  for (final a in rapor.ambarlar)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.warehouse_outlined,
                              size: 16, color: AppColors.slate400),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(a.ambarAdi,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('${_sayi(a.fiiliStok)} ${rapor.birim}',
                              style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700)),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 90,
                            child: Text(
                                'gerçek ${_sayi(a.gercekStok)}',
                                textAlign: TextAlign.right,
                                style: AppTypography.caption),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
