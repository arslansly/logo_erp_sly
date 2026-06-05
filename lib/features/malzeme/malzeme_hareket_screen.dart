import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../core/utils/pdf_onizleme_screen.dart';
import 'malzeme_model.dart';
import 'malzeme_service.dart';

enum _Filter { tumu, faturalar, irsaliyeler, uretim }

enum _Yon { tumu, giris, cikis }

extension on _Yon {
  String get label => switch (this) {
        _Yon.tumu => 'Tümü',
        _Yon.giris => 'Giriş',
        _Yon.cikis => 'Çıkış',
      };

  bool? get girisParam => switch (this) {
        _Yon.tumu => null,
        _Yon.giris => true,
        _Yon.cikis => false,
      };
}

extension on _Filter {
  String get label => switch (this) {
        _Filter.tumu => 'Tümü',
        _Filter.faturalar => 'Faturalar',
        _Filter.irsaliyeler => 'İrsaliyeler',
        _Filter.uretim => 'Üretim & Sarf',
      };

  bool matches(MalzemeHareket h) => switch (this) {
        _Filter.tumu => true,
        _Filter.faturalar => h.fatura,
        _Filter.irsaliyeler =>
          !h.fatura && const {1, 2, 3, 6, 7, 8}.contains(h.islemTipi),
        _Filter.uretim => const {11, 12, 13}.contains(h.islemTipi),
      };
}

class MalzemeHareketScreen extends StatefulWidget {
  final int malzemeId;
  final String malzemeAdi;
  final String birim;

  const MalzemeHareketScreen({
    super.key,
    required this.malzemeId,
    required this.malzemeAdi,
    required this.birim,
  });

  @override
  State<MalzemeHareketScreen> createState() => _MalzemeHareketScreenState();
}

class _MalzemeHareketScreenState extends State<MalzemeHareketScreen> {
  List<MalzemeHareket> _hareketler = [];
  bool _isLoading = true;
  String? _error;

  DateTime? _baslangic;
  DateTime? _bitis;
  _Filter _filter = _Filter.tumu;
  _Yon _yon = _Yon.tumu;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await malzemeService.getHareketler(
        widget.malzemeId,
        baslangic: _baslangic,
        bitis: _bitis,
        giris: _yon.girisParam,
      );
      if (!mounted) return;
      setState(() {
        _hareketler = data;
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = DateTimeRange(
      start: _baslangic ?? DateTime(now.year, now.month - 6, now.day),
      end: _bitis ?? now,
    );
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
      locale: const Locale('tr', 'TR'),
      helpText: 'Tarih aralığı',
      cancelText: 'Vazgeç',
      confirmText: 'Uygula',
      saveText: 'Uygula',
    );
    if (range == null) return;
    setState(() {
      _baslangic = range.start;
      _bitis = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    });
    await _loadData();
  }

  String _pdfDosyaAdi() {
    final safeName = widget.malzemeAdi
        .replaceAll(RegExp(r'[^a-zA-Z0-9ğüşöçıİĞÜŞÖÇ_-]+'), '_');
    final tarihEk = _baslangic != null && _bitis != null
        ? '_${DateFormat('yyyyMMdd').format(_baslangic!)}-${DateFormat('yyyyMMdd').format(_bitis!)}'
        : '';
    return 'MalzemeEkstre_$safeName$tarihEk';
  }

  List<MalzemeHareket> _filtreliHareketler() =>
      _hareketler.where(_filter.matches).toList();

  Future<void> _sharePdf() async {
    try {
      final bytes = await buildMalzemeEkstrePdf(
        malzemeId: widget.malzemeId,
        malzemeAdi: widget.malzemeAdi,
        birim: widget.birim,
        hareketler: _filtreliHareketler(),
        baslangic: _baslangic,
        bitis: _bitis,
      );
      await sharePdf(bytes, '${_pdfDosyaAdi()}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF oluşturulamadı: $e')),
      );
    }
  }

  void _onizlePdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfOnizlemeScreen(
          baslik: _pdfDosyaAdi(),
          pdfOlustur: () => buildMalzemeEkstrePdf(
            malzemeId: widget.malzemeId,
            malzemeAdi: widget.malzemeAdi,
            birim: widget.birim,
            hareketler: _filtreliHareketler(),
            baslangic: _baslangic,
            bitis: _bitis,
          ),
        ),
      ),
    );
  }

  void _clearDates() {
    setState(() {
      _baslangic = null;
      _bitis = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ekstre',
                style:
                    AppTypography.h2.copyWith(color: AppColors.slate900, fontSize: 18)),
            Text(widget.malzemeAdi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption
                    .copyWith(color: AppColors.slate500, fontSize: 11)),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: AppColors.slate700),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_rounded,
                color: AppColors.slate700),
            tooltip: 'PDF önizle',
            onPressed: _hareketler.isEmpty ? null : _onizlePdf,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.slate700),
            tooltip: 'PDF olarak paylaş',
            onPressed: _hareketler.isEmpty ? null : _sharePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.accent,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final fmt = DateFormat('d MMM yyyy', 'tr_TR');
    final hasDate = _baslangic != null || _bitis != null;
    final dateLabel = hasDate
        ? '${_baslangic != null ? fmt.format(_baslangic!) : '...'} → ${_bitis != null ? fmt.format(_bitis!) : '...'}'
        : 'Tarih aralığı seç';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text(
                    dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        hasDate ? AppColors.accent : AppColors.slate700,
                    side: BorderSide(
                      color: hasDate ? AppColors.accent : AppColors.slate300,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              if (hasDate)
                IconButton(
                  tooltip: 'Tarihi temizle',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.slate500,
                  onPressed: _clearDates,
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                for (final y in _Yon.values) ...[
                  Expanded(
                    child: _yonChip(y),
                  ),
                  if (y != _Yon.values.last) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _Filter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final f = _Filter.values[i];
                final selected = _filter == f;
                return ChoiceChip(
                  label: Text(f.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                  labelStyle: AppTypography.caption.copyWith(
                    color: selected ? Colors.white : AppColors.slate700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.slate100,
                  side: BorderSide(
                    color: selected ? AppColors.accent : AppColors.slate200,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _yonChip(_Yon y) {
    final selected = _yon == y;
    final Color color = switch (y) {
      _Yon.giris => AppColors.positive,
      _Yon.cikis => AppColors.negative,
      _Yon.tumu => AppColors.accent,
    };
    return Material(
      color: selected ? color : AppColors.slate100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (_yon == y) return;
          setState(() => _yon = y);
          _loadData();
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.slate200,
            ),
          ),
          child: Text(
            y.label,
            style: AppTypography.caption.copyWith(
              color: selected ? Colors.white : AppColors.slate700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();

    final filtered = _hareketler.where(_filter.matches).toList();
    if (filtered.isEmpty) return _buildEmpty();

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          _HareketCard(hareket: filtered[i], birim: widget.birim),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => Container(
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.negativeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    color: AppColors.negative, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Yüklenemedi',
                  style: AppTypography.h2.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.slate600)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 56, color: AppColors.slate400),
              const SizedBox(height: 12),
              Text('Hareket yok',
                  style:
                      AppTypography.h2.copyWith(color: AppColors.slate600)),
              const SizedBox(height: 4),
              Text('Bu filtreyle gösterilecek hareket bulunamadı.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.slate500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HareketCard extends StatelessWidget {
  final MalzemeHareket hareket;
  final String birim;
  const _HareketCard({required this.hareket, required this.birim});

  @override
  Widget build(BuildContext context) {
    final tarihFmt = DateFormat('d MMM yyyy', 'tr_TR');
    final sayiFmt = NumberFormat.decimalPattern('tr_TR');
    final paraFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '');

    final renk = hareket.giris ? AppColors.positive : AppColors.negative;
    final bgRenk = hareket.giris ? AppColors.positiveBg : AppColors.negativeBg;
    final isaret = hareket.giris ? '+' : '−';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgRenk,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hareket.giris
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: renk,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hareket.islemTipiAdi,
                      style: AppTypography.h3.copyWith(
                          color: AppColors.slate900, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tarihFmt.format(hareket.tarih),
                      style: AppTypography.caption.copyWith(
                          color: AppColors.slate500, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$isaret${sayiFmt.format(hareket.miktar)} $birim',
                    style: AppTypography.h3.copyWith(
                        color: renk, fontSize: 14),
                  ),
                  if (hareket.birimFiyat > 0)
                    Text(
                      '${sayiFmt.format(hareket.birimFiyat)} × ',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.slate500, fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
          if (hareket.ambar.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 46),
                Icon(Icons.warehouse_outlined,
                    size: 13, color: AppColors.slate400),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    hareket.ambar,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                        color: AppColors.slate600, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
          if (hareket.fisNo.isNotEmpty ||
              hareket.cariAdi.isNotEmpty ||
              hareket.tutar > 0) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.slate200),
            const SizedBox(height: 8),
            Row(
              children: [
                if (hareket.fisNo.isNotEmpty) ...[
                  const Icon(Icons.receipt_outlined,
                      size: 14, color: AppColors.slate400),
                  const SizedBox(width: 4),
                  Text(hareket.fisNo,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.slate600, fontSize: 11)),
                ],
                if (hareket.cariAdi.isNotEmpty) ...[
                  if (hareket.fisNo.isNotEmpty) const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      hareket.cariAdi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                          color: AppColors.slate600, fontSize: 11),
                    ),
                  ),
                ],
                const Spacer(),
                if (hareket.tutar > 0)
                  Text(
                    paraFmt.format(hareket.tutar),
                    style: AppTypography.caption.copyWith(
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w600,
                        fontSize: 11),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
