import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/pdf/belge_pdf.dart';
import '../../core/pdf/belge_onizleme_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../irsaliye/irsaliye_detay_screen.dart';
import '../siparis/siparis_detay_screen.dart';
import 'fatura_form_screen.dart';
import 'fatura_model.dart';
import 'fatura_service.dart';
import 'fatura_taslak_service.dart';

/// Fatura detay ekranı — header + satırlar + bağlı belgeler + aksiyonlar.
/// Hem LOGO faturası hem taslak fatura için çalışır (FaturaModel.isDraft farkı).
class FaturaDetayScreen extends StatefulWidget {
  final FaturaModel fatura;
  const FaturaDetayScreen({super.key, required this.fatura});

  @override
  State<FaturaDetayScreen> createState() => _FaturaDetayScreenState();
}

class _FaturaDetayScreenState extends State<FaturaDetayScreen> {
  FaturaDetayModel? _detay;
  FaturaTaslakModel? _taslakDetay;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (widget.fatura.isDraft) {
        final t = await faturaTaslakService.getTaslakById(widget.fatura.id);
        if (!mounted) return;
        setState(() {
          _taslakDetay = t;
          _isLoading = false;
        });
      } else {
        final d = await faturaService.getFaturaDetay(widget.fatura.id);
        if (!mounted) return;
        setState(() {
          _detay = d;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Yüklü fatura/taslak verisinden paylaşılabilir belge görseli (PDF) üretir.
  BelgePdfData _pdfData() {
    // LOGO faturası
    if (_detay != null) {
      final d = _detay!;
      final f = d.baslik;
      return BelgePdfData(
        belgeBasligi: f.trCodeName.isEmpty ? f.displayAd : f.trCodeName,
        durumEtiketi: f.cancelled == 1 ? 'İPTAL' : null,
        fisNo: f.ficheNo,
        belgeNo: f.docCode,
        tarih: f.date,
        cariUnvan: f.clientTitle,
        cariKod: f.clientCode,
        satirlar: [
          for (var i = 0; i < d.satirlar.length; i++)
            BelgePdfSatir(
              sira: i + 1,
              kod: d.satirlar[i].stockCode,
              ad: d.satirlar[i].stockName.isEmpty
                  ? d.satirlar[i].lineDescription
                  : d.satirlar[i].stockName,
              miktar: d.satirlar[i].amount,
              birim: d.satirlar[i].uomCode,
              fiyat: d.satirlar[i].price,
              kdvOran: d.satirlar[i].vatRate,
              tutar: d.satirlar[i].lineNet,
            ),
        ],
        brut: f.grossTotal,
        iskonto: f.totalDiscounts,
        kdv: f.totalVat,
        net: f.netTotal,
        aciklamalar: d.aciklamalar.toList(),
        dosyaAdi: 'Fatura_${f.ficheNo.isEmpty ? f.id : f.ficheNo}',
      );
    }

    // Taslak fatura
    final t = _taslakDetay!;
    return BelgePdfData(
      belgeBasligi: FaturaTuru.fromTrCode(t.trCode)?.adi ?? 'Taslak Fatura',
      durumEtiketi: t.status == 'Failed' ? 'HATALI' : 'TASLAK',
      fisNo: t.ficheNo ?? '',
      belgeNo: t.docCode ?? '',
      tarih: t.date,
      cariUnvan: t.clientTitle,
      cariKod: t.clientCode,
      satirlar: [
        for (var i = 0; i < t.lines.length; i++)
          BelgePdfSatir(
            sira: i + 1,
            kod: t.lines[i].stockCode ?? '',
            ad: (t.lines[i].stockName?.isNotEmpty ?? false)
                ? t.lines[i].stockName!
                : (t.lines[i].lineDescription ?? ''),
            miktar: t.lines[i].amount,
            birim: t.lines[i].uomCode ?? '',
            fiyat: t.lines[i].price,
            kdvOran: t.lines[i].vatRate,
            tutar: t.lines[i].total,
          ),
      ],
      brut: t.grossTotal,
      iskonto: t.totalDiscounts,
      kdv: t.totalVat,
      net: t.netTotal,
      aciklamalar: [
        if (t.genExp1?.isNotEmpty == true) t.genExp1!,
        if (t.genExp2?.isNotEmpty == true) t.genExp2!,
      ],
      dosyaAdi: 'TaslakFatura_${(t.ficheNo?.isNotEmpty ?? false) ? t.ficheNo : t.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.fatura.isDraft ? 'Taslak Fatura' : 'Fatura Detayı'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppTypography.h2,
        foregroundColor: AppColors.slate900,
        actions: [
          if (_detay != null || _taslakDetay != null)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Çıktı / Önizleme',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BelgeOnizlemeScreen(data: _pdfData()),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.slate300),
            const SizedBox(height: AppSpacing.md),
            Text(_error!,
                style: AppTypography.body.copyWith(color: AppColors.slate600),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.fatura.isDraft && _taslakDetay != null) {
      return _buildDraftBody(_taslakDetay!);
    }
    if (!widget.fatura.isDraft && _detay != null) {
      return _buildInvoiceBody(_detay!);
    }
    return const SizedBox.shrink();
  }

  // ── LOGO faturası gövdesi ──
  Widget _buildInvoiceBody(FaturaDetayModel d) {
    final f = d.baslik;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
      children: [
        _HeroKart(fatura: f, draftStatus: null),
        const SizedBox(height: AppSpacing.md),
        _SatirlarSection(satirlar: d.satirlar),
        const SizedBox(height: AppSpacing.md),
        _ToplamlarKart(
          brut: f.grossTotal,
          iskonto: f.totalDiscounts,
          kdv: f.totalVat,
          net: f.netTotal,
        ),
        if (d.irsaliyeler.isNotEmpty || d.siparisler.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _BagliBelgelerSection(
            irsaliyeler: d.irsaliyeler,
            siparisler: d.siparisler,
          ),
        ],
        if (d.aciklamalar.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _AciklamalarKart(aciklamalar: d.aciklamalar.toList()),
        ],
      ],
    );
  }

  // ── Taslak fatura gövdesi ──
  Widget _buildDraftBody(FaturaTaslakModel t) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
      children: [
        _HeroKart(
          fatura: FaturaModel(
            id: t.id ?? 0,
            ficheNo: t.ficheNo ?? '',
            docCode: t.docCode ?? '',
            date: t.date,
            trCode: t.trCode,
            trCodeName: FaturaTuru.fromTrCode(t.trCode)?.adi ?? '',
            clientRef: t.clientRef,
            clientCode: t.clientCode,
            clientTitle: t.clientTitle,
            netTotal: t.netTotal,
            grossTotal: t.grossTotal,
            totalVat: t.totalVat,
            totalDiscounts: t.totalDiscounts,
            cancelled: 0,
            isDraft: true,
            draftStatus: t.status,
            lastError: t.lastError,
          ),
          draftStatus: t.status,
        ),
        if (t.status == 'Failed' && t.lastError != null) ...[
          const SizedBox(height: AppSpacing.md),
          _HataKart(mesaj: t.lastError!),
        ],
        const SizedBox(height: AppSpacing.md),
        _AksiyonBar(
          onPdf: null,
          onShare: null,
          onEdit: () => _editTaslak(t.id!),
          onTransfer: () => _transferTaslak(t.id!),
        ),
        const SizedBox(height: AppSpacing.md),
        _TaslakSatirlarSection(satirlar: t.lines),
        const SizedBox(height: AppSpacing.md),
        _ToplamlarKart(
          brut: t.grossTotal,
          iskonto: t.totalDiscounts,
          kdv: t.totalVat,
          net: t.netTotal,
        ),
        if (t.genExp1?.isNotEmpty == true || t.genExp2?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.md),
          _AciklamalarKart(aciklamalar: [
            if (t.genExp1?.isNotEmpty == true) t.genExp1!,
            if (t.genExp2?.isNotEmpty == true) t.genExp2!,
          ]),
        ],
      ],
    );
  }

  Future<void> _editTaslak(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaturaFormScreen(taslakId: id)),
    );
    if (!mounted) return;
    _load();
  }

  Future<void> _transferTaslak(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final newId = await faturaTaslakService.transferTaslak(id);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.positive,
        content: Text('LOGO\'ya aktarıldı (#$newId)'),
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.negative,
        content: Text('Aktarım başarısız: $e'),
        duration: const Duration(seconds: 5),
      ));
      _load();
    }
  }
}

// ─── Hero kart ─────────────────────────────────────────────────────────────
class _HeroKart extends StatelessWidget {
  final FaturaModel fatura;
  final String? draftStatus;
  const _HeroKart({required this.fatura, this.draftStatus});

  @override
  Widget build(BuildContext context) {
    final renk = fatura.displayRenk;
    final isFailed = draftStatus == 'Failed';
    final isDraft = draftStatus == 'Draft';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [renk, renk.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: renk.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(fatura.displayIkon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  fatura.displayAd,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isDraft || isFailed)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFailed
                        ? AppColors.negative.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isFailed ? 'HATALI' : 'TASLAK',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            fatura.clientTitle.isEmpty ? '(Cari yok)' : fatura.clientTitle,
            style: AppTypography.h2.copyWith(color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${fatura.ficheNo.isEmpty ? "Fiş no yok" : "Fiş: ${fatura.ficheNo}"}'
            ' • ${_fmtDate(fatura.date)}',
            style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Net Toplam',
                        style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 2),
                    Text(_fmtCurrency(fatura.netTotal),
                        style: AppTypography.display.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                        )),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Brüt',
                      style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8))),
                  Text(_fmtCurrency(fatura.grossTotal),
                      style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('KDV',
                      style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8))),
                  Text(_fmtCurrency(fatura.totalVat),
                      style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Aksiyon barı ──────────────────────────────────────────────────────────
class _AksiyonBar extends StatelessWidget {
  final VoidCallback? onPdf;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onTransfer;

  const _AksiyonBar({
    this.onPdf,
    this.onShare,
    this.onEdit,
    this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onPdf != null)
          Expanded(
            child: _AksiyonBtn(
              icon: Icons.picture_as_pdf_rounded,
              label: 'PDF',
              onTap: onPdf,
            ),
          ),
        if (onShare != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _AksiyonBtn(
              icon: Icons.share_rounded,
              label: 'Paylaş',
              onTap: onShare,
            ),
          ),
        ],
        if (onEdit != null) ...[
          if (onPdf != null) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _AksiyonBtn(
              icon: Icons.edit_rounded,
              label: 'Düzenle',
              onTap: onEdit,
            ),
          ),
        ],
        if (onTransfer != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _AksiyonBtn(
              icon: Icons.cloud_upload_rounded,
              label: 'LOGO\'ya Aktar',
              onTap: onTransfer,
              primary: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _AksiyonBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  const _AksiyonBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? AppColors.primary : AppColors.surface;
    final fg = primary ? AppColors.surface : AppColors.slate700;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: primary ? null : Border.all(color: AppColors.slate200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTypography.caption
                      .copyWith(color: fg, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Satırlar bölümü (LOGO) ────────────────────────────────────────────────
class _SatirlarSection extends StatelessWidget {
  final List<FaturaSatirModel> satirlar;
  const _SatirlarSection({required this.satirlar});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      baslik: 'Satırlar (${satirlar.length})',
      ikon: Icons.format_list_bulleted_rounded,
      child: satirlar.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Satır yok',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.slate500)),
            )
          : Column(
              children: satirlar
                  .map((s) => _SatirRow(satir: s))
                  .toList(),
            ),
    );
  }
}

class _TaslakSatirlarSection extends StatelessWidget {
  final List<FaturaTaslakSatirModel> satirlar;
  const _TaslakSatirlarSection({required this.satirlar});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      baslik: 'Satırlar (${satirlar.length})',
      ikon: Icons.format_list_bulleted_rounded,
      child: satirlar.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Satır yok',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.slate500)),
            )
          : Column(
              children: satirlar.map((s) {
                final fakeSatir = FaturaSatirModel(
                  id: s.id ?? 0,
                  lineNo: s.lineNo,
                  lineType: s.lineType,
                  lineTypeName: _lineTypeName(s.lineType),
                  stockRef: s.stockRef,
                  stockCode: s.stockCode ?? '',
                  stockName: s.stockName ?? '',
                  uomCode: s.uomCode ?? '',
                  amount: s.amount,
                  price: s.price,
                  vatRate: s.vatRate,
                  total: s.total,
                  vatAmount: s.vatAmount,
                  lineNet: s.lineNet,
                  discount: s.discount,
                  lineDescription: s.lineDescription ?? '',
                );
                return _SatirRow(satir: fakeSatir);
              }).toList(),
            ),
    );
  }
}

String _lineTypeName(int t) => switch (t) {
      0 => 'Malzeme',
      1 => 'Hizmet',
      2 => 'Masraf',
      4 => 'İskonto',
      _ => 'Tip $t',
    };

class _SatirRow extends StatelessWidget {
  final FaturaSatirModel satir;
  const _SatirRow({required this.satir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.slate200, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: satir.lineTypeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  satir.stockName.isEmpty
                      ? (satir.lineDescription.isEmpty
                          ? '(${satir.lineTypeName})'
                          : satir.lineDescription)
                      : satir.stockName,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtNum(satir.amount)} ${satir.uomCode} × ${_fmtCurrency(satir.price)}'
                  '${satir.vatRate > 0 ? "  •  KDV %${satir.vatRate.toStringAsFixed(0)}" : ""}',
                  style: AppTypography.caption,
                ),
                if (satir.discount > 0)
                  Text('İsk: ${_fmtCurrency(satir.discount)}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.negative)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _fmtCurrency(satir.lineNet),
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─── Toplamlar kartı ───────────────────────────────────────────────────────
class _ToplamlarKart extends StatelessWidget {
  final double brut, iskonto, kdv, net;
  const _ToplamlarKart({
    required this.brut,
    required this.iskonto,
    required this.kdv,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      baslik: 'Toplamlar',
      ikon: Icons.calculate_rounded,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _line('Brüt Toplam', brut, false),
            const SizedBox(height: 6),
            _line('İskonto', -iskonto, false, neg: iskonto > 0),
            const SizedBox(height: 6),
            _line('KDV', kdv, false),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.slate200),
            const SizedBox(height: AppSpacing.sm),
            _line('Net Toplam', net, true),
          ],
        ),
      ),
    );
  }

  Widget _line(String l, double v, bool bold, {bool neg = false}) {
    final style = bold
        ? AppTypography.h2.copyWith(fontWeight: FontWeight.w700)
        : AppTypography.body;
    final valStyle = bold
        ? AppTypography.h2
            .copyWith(fontWeight: FontWeight.w700, color: AppColors.slate900)
        : AppTypography.body.copyWith(
            color: neg ? AppColors.negative : AppColors.slate800,
            fontWeight: FontWeight.w600,
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: style),
        Text(_fmtCurrency(v), style: valStyle),
      ],
    );
  }
}

// ─── Bağlı belgeler bölümü ─────────────────────────────────────────────────
class _BagliBelgelerSection extends StatelessWidget {
  final List<BagliBelgeModel> irsaliyeler;
  final List<BagliBelgeModel> siparisler;
  const _BagliBelgelerSection({
    required this.irsaliyeler,
    required this.siparisler,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      baslik: 'Bağlı Belgeler',
      ikon: Icons.link_rounded,
      child: Column(
        children: [
          if (irsaliyeler.isNotEmpty) ...[
            _belgeGrubu(
              context,
              baslik: 'İrsaliyeler (${irsaliyeler.length})',
              ikon: Icons.local_shipping_outlined,
              renk: AppColors.violet,
              belgeler: irsaliyeler,
              onBelgeTap: (b) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IrsaliyeDetayScreen(id: b.id),
                ),
              ),
            ),
          ],
          if (siparisler.isNotEmpty) ...[
            _belgeGrubu(
              context,
              baslik: 'Siparişler (${siparisler.length})',
              ikon: Icons.assignment_outlined,
              renk: AppColors.cyan,
              belgeler: siparisler,
              onBelgeTap: (b) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SiparisDetayScreen(id: b.id),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _belgeGrubu(
    BuildContext context, {
    required String baslik,
    required IconData ikon,
    required Color renk,
    required List<BagliBelgeModel> belgeler,
    required ValueChanged<BagliBelgeModel> onBelgeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          child: Row(
            children: [
              Icon(ikon, size: 16, color: renk),
              const SizedBox(width: 6),
              Text(baslik,
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700, color: renk)),
            ],
          ),
        ),
        ...belgeler.map((b) => InkWell(
              onTap: () => onBelgeTap(b),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppColors.slate200, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.ficheNo.isEmpty ? '(Fiş no yok)' : b.ficheNo,
                              style: AppTypography.body
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text('${b.trCodeName} • ${_fmtDate(b.date)}',
                              style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Text(_fmtCurrency(b.total),
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.slate400),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ─── Açıklamalar kartı ─────────────────────────────────────────────────────
class _AciklamalarKart extends StatelessWidget {
  final List<String> aciklamalar;
  const _AciklamalarKart({required this.aciklamalar});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      baslik: 'Açıklamalar',
      ikon: Icons.notes_rounded,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: aciklamalar
              .map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(a, style: AppTypography.body),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ─── Hata kartı (taslak failed) ────────────────────────────────────────────
class _HataKart extends StatelessWidget {
  final String mesaj;
  const _HataKart({required this.mesaj});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.negativeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.negative.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.negative),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aktarım Hatası',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.negative,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Text(mesaj,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.negative)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section container (ortak başlık + içerik) ────────────────────────────
class _SectionContainer extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final Widget child;
  const _SectionContainer({
    required this.baslik,
    required this.ikon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              children: [
                Icon(ikon, size: 18, color: AppColors.slate600),
                const SizedBox(width: AppSpacing.sm),
                Text(baslik, style: AppTypography.h3),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

// ─── helpers ───────────────────────────────────────────────────────────────
String _fmtCurrency(double v) =>
    NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(v);

String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);

String _fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}
