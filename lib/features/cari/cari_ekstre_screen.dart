import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../core/utils/pdf_onizleme_screen.dart';
import 'cari_ekstre_model.dart';
import 'cari_model.dart';
import 'cari_service.dart';

class CariEkstreScreen extends StatefulWidget {
  final Cari cari;

  const CariEkstreScreen({super.key, required this.cari});

  @override
  State<CariEkstreScreen> createState() => _CariEkstreScreenState();
}

class _CariEkstreScreenState extends State<CariEkstreScreen> {
  late DateTime _baslangic;
  late DateTime _bitis;
  CariEkstre? _ekstre;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baslangic = DateTime(now.year, 1, 1);
    _bitis = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ekstre = await cariService.getEkstre(
        widget.cari.id,
        baslangic: _baslangic,
        bitis: _bitis,
      );
      if (!mounted) return;
      setState(() {
        _ekstre = ekstre;
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

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _baslangic, end: _bitis),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Tarih aralığı seç',
      cancelText: 'Vazgeç',
      confirmText: 'Tamam',
      saveText: 'Kaydet',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.accent,
              ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      _baslangic = range.start;
      _bitis = range.end;
      await _load();
    }
  }

  String _formatTarih(DateTime d) => DateFormat('d MMM yyyy', 'tr_TR').format(d);

  String _pdfDosyaAdi() {
    final safeName = widget.cari.title
        .replaceAll(RegExp(r'[^a-zA-Z0-9ğüşöçıİĞÜŞÖÇ_-]+'), '_');
    return 'Ekstre_${safeName}_${DateFormat('yyyyMMdd').format(_baslangic)}-${DateFormat('yyyyMMdd').format(_bitis)}';
  }

  Future<void> _sharePdf() async {
    final ekstre = _ekstre;
    if (ekstre == null) return;
    try {
      final bytes = await buildCariEkstrePdf(cari: widget.cari, ekstre: ekstre);
      await sharePdf(bytes, '${_pdfDosyaAdi()}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF oluşturulamadı: $e')),
      );
    }
  }

  void _onizlePdf() {
    final ekstre = _ekstre;
    if (ekstre == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfOnizlemeScreen(
          baslik: _pdfDosyaAdi(),
          pdfOlustur: () => buildCariEkstrePdf(
            cari: widget.cari,
            ekstre: ekstre,
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
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ekstre',
              style: AppTypography.h2.copyWith(fontSize: 16),
            ),
            Text(
              widget.cari.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.slate500,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_rounded),
            color: AppColors.slate700,
            tooltip: 'PDF önizle',
            onPressed: _ekstre == null ? null : _onizlePdf,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            color: AppColors.slate700,
            tooltip: 'PDF olarak paylaş',
            onPressed: _ekstre == null ? null : _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            color: AppColors.slate700,
            tooltip: 'Tarih aralığı',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_error != null && _ekstre == null) return _buildError(_error!);
    final e = _ekstre!;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(e)),
        if (e.hareketler.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmpty(),
          )
        else
          SliverList.builder(
            itemCount: e.hareketler.length,
            itemBuilder: (context, i) => _buildSatir(e.hareketler[i], i == 0),
          ),
        SliverToBoxAdapter(child: _buildFooter(e)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // ─── Header (tarih aralığı + devir/kapanış) ───
  Widget _buildHeader(CariEkstre e) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppColors.slate500),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatTarih(e.baslangicTarihi)} – ${_formatTarih(e.bitisTarihi)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.slate600,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: AppColors.slate400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _balanceTile(
                    label: 'Devir bakiyesi',
                    value: e.devirBakiyesi,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: AppColors.slate200,
                ),
                Expanded(
                  child: _balanceTile(
                    label: 'Kapanış bakiyesi',
                    value: e.kapanisBakiyesi,
                    bold: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceTile({
    required String label,
    required double value,
    bool bold = false,
  }) {
    final isPositive = value > 0;
    final isNegative = value < 0;
    final color = isPositive
        ? AppColors.negative
        : isNegative
            ? AppColors.positive
            : AppColors.slate700;
    final sign = isNegative ? '-' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.slate500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$sign${Formatters.currency(value.abs())}',
          style: AppTypography.h2.copyWith(
            fontSize: bold ? 18 : 16,
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Satır ───
  Widget _buildSatir(CariEkstreSatir s, bool isFirst) {
    final hasBorc = s.borc > 0;
    final tutarColor = hasBorc ? AppColors.negative : AppColors.positive;
    final sign = hasBorc ? '' : '-';
    final tutar = hasBorc ? s.borc : s.alacak;
    final yurNeg = s.yurutulenBakiye < 0;

    return Container(
      margin: EdgeInsets.fromLTRB(16, isFirst ? 4 : 0, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 14 : 0),
          topRight: Radius.circular(isFirst ? 14 : 0),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 42,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMM', 'tr_TR').format(s.tarih),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy').format(s.tarih),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.slate400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.islemTipiAdi.isEmpty
                            ? 'İşlem #${s.islemTipi}'
                            : s.islemTipiAdi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontSize: 13,
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (s.documentNo.isNotEmpty || s.aciklama.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (s.documentNo.isNotEmpty) '№ ${s.documentNo}',
                            if (s.aciklama.isNotEmpty) s.aciklama,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.slate500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign${Formatters.currency(tutar)}',
                      style: AppTypography.body.copyWith(
                        fontSize: 13,
                        color: tutarColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${yurNeg ? '-' : ''}${Formatters.currency(s.yurutulenBakiye.abs())}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.slate500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(height: 0.5, color: AppColors.slate200),
          ),
        ],
      ),
    );
  }

  // ─── Footer ───
  Widget _buildFooter(CariEkstre e) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: _footerCell(
                'Toplam Borç',
                e.toplamBorc,
                AppColors.negative,
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: AppColors.slate200,
            ),
            Expanded(
              child: _footerCell(
                'Toplam Alacak',
                e.toplamAlacak,
                AppColors.positive,
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: AppColors.slate200,
            ),
            Expanded(
              child: _footerCell(
                'Net',
                e.netHareket,
                e.netHareket >= 0 ? AppColors.negative : AppColors.positive,
                signed: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerCell(String label, double value, Color color,
      {bool signed = false}) {
    final sign = signed && value < 0 ? '-' : '';
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.slate500,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$sign${Formatters.currency(value.abs())}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ─── States ───
  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(
          6,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56, color: AppColors.slate400),
            const SizedBox(height: 12),
            Text(
              'Bu aralıkta hareket yok',
              style: AppTypography.h3
                  .copyWith(color: AppColors.slate600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Tarih aralığını değiştirip tekrar dene',
              style:
                  AppTypography.caption.copyWith(color: AppColors.slate500),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('Tarih aralığını değiştir'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
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
            Text('Ekstre alınamadı',
                style: AppTypography.h2.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.slate600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
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
}
