import 'dart:async';

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

// Cari hesap/bakiye raporu — kod, ünvan, şehir/ülke, telefon, borç, alacak, bakiye.
class CariBakiyeRaporScreen extends StatefulWidget {
  const CariBakiyeRaporScreen({super.key});

  @override
  State<CariBakiyeRaporScreen> createState() => _CariBakiyeRaporScreenState();
}

class _CariBakiyeRaporScreenState extends State<CariBakiyeRaporScreen> {
  List<CariBakiyeRapor> _liste = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  Timer? _debounce;
  int? _tur; // CLCARD.CARDTYPE: 1=Alıcı, 2=Satıcı
  String? _bakiyeDurumu; // 'borclu' | 'alacakli'

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
      final sonuc = await raporService.getCariBakiye(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        tur: _tur,
        bakiyeDurumu: _bakiyeDurumu,
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

  void _setBakiye(String? b) {
    setState(() => _bakiyeDurumu = b);
    _load();
  }

  Future<void> _pdfAc() async {
    final filtre = <String>[
      if (_searchQuery.isNotEmpty) 'Arama: $_searchQuery',
      if (_tur == 1) 'Alıcı' else if (_tur == 2) 'Satıcı',
      if (_bakiyeDurumu == 'borclu')
        'Borçlu'
      else if (_bakiyeDurumu == 'alacakli')
        'Alacaklı',
    ].join(' · ');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfOnizlemeScreen(
          baslik: 'Cari Bakiye Raporu',
          pdfOlustur: () => buildTabloRaporPdf(
            baslik: 'Cari Bakiye Raporu',
            altBilgi: filtre,
            kolonlar: const [
              'Kod',
              'Ünvan',
              'Şehir',
              'Telefon',
              'Borç',
              'Alacak',
              'Bakiye',
            ],
            sagKolonlar: const {4, 5, 6},
            genislikler: const [1.3, 3, 1.4, 1.5, 1.5, 1.5, 1.6],
            satirlar: _liste
                .map((c) => [
                      c.code,
                      c.title,
                      [c.city, c.country].where((s) => s.isNotEmpty).join(' / '),
                      c.phone,
                      Formatters.currency(c.toplamBorc),
                      Formatters.currency(c.toplamAlacak),
                      Formatters.currency(c.bakiye),
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
        title: const Text('Cari Bakiye'),
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
                  hint: 'Cari ara — ünvan, kod, şehir...',
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
                    RaporChip(
                        label: 'Alıcı',
                        selected: _tur == 1,
                        onTap: () => _setTur(1)),
                    RaporChip(
                        label: 'Satıcı',
                        selected: _tur == 2,
                        onTap: () => _setTur(2)),
                    Container(
                        width: 1,
                        height: 22,
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 11),
                        color: AppColors.slate200),
                    RaporChip(
                        label: 'Borçlu',
                        selected: _bakiyeDurumu == 'borclu',
                        aktifRenk: AppColors.negative,
                        onTap: () => _setBakiye(
                            _bakiyeDurumu == 'borclu' ? null : 'borclu')),
                    RaporChip(
                        label: 'Alacaklı',
                        selected: _bakiyeDurumu == 'alacakli',
                        aktifRenk: AppColors.positive,
                        onTap: () => _setBakiye(
                            _bakiyeDurumu == 'alacakli' ? null : 'alacakli')),
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
      itemBuilder: (_, i) => _CariBakiyeCard(rapor: _liste[i]),
    );
  }
}

class _CariBakiyeCard extends StatelessWidget {
  final CariBakiyeRapor rapor;
  const _CariBakiyeCard({required this.rapor});

  @override
  Widget build(BuildContext context) {
    final bakiyeRenk = rapor.isBorclu
        ? AppColors.negative
        : rapor.isAlacakli
            ? AppColors.positive
            : AppColors.slate600;
    final konum =
        [rapor.city, rapor.country].where((s) => s.isNotEmpty).join(' / ');

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
                    Text(rapor.code, style: AppTypography.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Formatters.currency(rapor.bakiye),
                      style: AppTypography.h3.copyWith(color: bakiyeRenk)),
                  const SizedBox(height: 2),
                  Text(
                    rapor.isBorclu
                        ? 'Borçlu'
                        : rapor.isAlacakli
                            ? 'Alacaklı'
                            : 'Bakiye yok',
                    style: AppTypography.caption.copyWith(color: bakiyeRenk),
                  ),
                ],
              ),
            ],
          ),
          if (konum.isNotEmpty || rapor.phone.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (konum.isNotEmpty) ...[
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.slate400),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text(konum,
                          style: AppTypography.caption,
                          overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: AppSpacing.md),
                ],
                if (rapor.phone.isNotEmpty) ...[
                  const Icon(Icons.phone_outlined,
                      size: 14, color: AppColors.slate400),
                  const SizedBox(width: 4),
                  Text(rapor.phone, style: AppTypography.caption),
                ],
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _miniTutar('Borç', rapor.toplamBorc, AppColors.negative),
              _miniTutar('Alacak', rapor.toplamAlacak, AppColors.positive),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTutar(String etiket, double tutar, Color renk) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket, style: AppTypography.caption),
          const SizedBox(height: 2),
          Text(Formatters.currency(tutar),
              style: AppTypography.bodySmall
                  .copyWith(color: renk, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
