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

// Kritik stok raporu — fiili stoğu asgari (MINLEVEL) seviyesinin altındaki malzemeler.
class KritikStokRaporScreen extends StatefulWidget {
  const KritikStokRaporScreen({super.key});

  @override
  State<KritikStokRaporScreen> createState() => _KritikStokRaporScreenState();
}

class _KritikStokRaporScreenState extends State<KritikStokRaporScreen> {
  List<KritikStokRapor> _liste = [];
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
      final sonuc = await raporService.getKritikStok(
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfOnizlemeScreen(
          baslik: 'Kritik Stok Raporu',
          pdfOlustur: () => buildTabloRaporPdf(
            baslik: 'Kritik Stok Raporu',
            altBilgi: filtre,
            ozetler: [('Kritik Malzeme', '${_liste.length}')],
            kolonlar: const [
              'Kod',
              'Malzeme',
              'Birim',
              'Fiili',
              'Asgari',
              'Fark',
            ],
            sagKolonlar: const {3, 4, 5},
            genislikler: const [1.5, 3.5, 1, 1.2, 1.2, 1.2],
            satirlar: _liste
                .map((k) => [
                      k.kod,
                      k.ad,
                      k.birim,
                      _sayi(k.fiiliStok),
                      _sayi(k.asgariStok),
                      _sayi(k.fark),
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
        title: const Text('Kritik Stok'),
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
    if (_isLoading) return const RaporLoading();
    if (_error != null && _liste.isEmpty) {
      return RaporError(mesaj: _error!, onRetry: _load);
    }
    if (_liste.isEmpty) {
      return const RaporEmpty(
          mesaj: 'Kritik stok yok', ikon: Icons.check_circle_outline);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _liste.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _KritikCard(rapor: _liste[i]),
    );
  }
}

String _sayi(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

class _KritikCard extends StatelessWidget {
  final KritikStokRapor rapor;
  const _KritikCard({required this.rapor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.negativeBg, width: 1.5),
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
                    const SizedBox(height: 2),
                    Text(rapor.kod, style: AppTypography.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.negativeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_sayi(rapor.fark)} ${rapor.birim}',
                    style: AppTypography.caption.copyWith(
                        color: AppColors.negative,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _mini('Fiili', rapor.fiiliStok, rapor.birim, AppColors.negative),
              _mini('Asgari', rapor.asgariStok, rapor.birim, AppColors.slate700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String etiket, double deger, String birim, Color renk) {
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
