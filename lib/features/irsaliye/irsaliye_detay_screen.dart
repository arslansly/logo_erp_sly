import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/pdf/belge_pdf.dart';
import '../../core/pdf/belge_onizleme_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../fatura/fatura_detay_screen.dart';
import '../fatura/fatura_model.dart';
import 'irsaliye_model.dart';
import 'irsaliye_service.dart';

class IrsaliyeDetayScreen extends StatefulWidget {
  final int id;
  const IrsaliyeDetayScreen({super.key, required this.id});

  @override
  State<IrsaliyeDetayScreen> createState() => _IrsaliyeDetayScreenState();
}

class _IrsaliyeDetayScreenState extends State<IrsaliyeDetayScreen> {
  IrsaliyeDetayModel? _detay;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await irsaliyeService.getDetay(widget.id);
      if (!mounted) return;
      setState(() {
        _detay = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('İrsaliye Detayı'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppTypography.h2,
        foregroundColor: AppColors.slate900,
        actions: [
          if (_detay != null)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Paylaş / Yazdır',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BelgeOnizlemeScreen(data: _pdfData(_detay!)),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  BelgePdfData _pdfData(IrsaliyeDetayModel d) {
    final b = d.baslik;
    final brut = d.satirlar.fold<double>(0, (s, l) => s + l.total);
    final iskonto = d.satirlar.fold<double>(0, (s, l) => s + l.discount);
    final kdv = d.satirlar.fold<double>(0, (s, l) => s + l.vatAmount);
    final ek = <String, String>{};
    if (b.isFaturalandi && b.invNo.isNotEmpty) ek['Fatura No'] = b.invNo;
    return BelgePdfData(
      belgeBasligi: b.trCodeName.isEmpty ? 'İrsaliye' : b.trCodeName,
      durumEtiketi: b.isFaturalandi ? 'Faturalandı' : 'Faturalanmamış',
      fisNo: b.ficheNo,
      belgeNo: b.docCode,
      tarih: b.date,
      cariUnvan: b.clientTitle,
      cariKod: b.clientCode,
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
      brut: brut,
      iskonto: iskonto,
      kdv: kdv,
      net: b.netTotal,
      aciklamalar: d.aciklamalar.toList(),
      ekBilgiler: ek,
      dosyaAdi: 'Irsaliye_${b.ficheNo.isEmpty ? b.id : b.ficheNo}',
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.negative),
            const SizedBox(height: AppSpacing.md),
            Text(_error!,
                textAlign: TextAlign.center, style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
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
    final d = _detay!;
    final tur = d.baslik.tur;

    final brut = d.satirlar.fold<double>(0, (s, l) => s + l.total);
    final iskonto = d.satirlar.fold<double>(0, (s, l) => s + l.discount);
    final kdv = d.satirlar.fold<double>(0, (s, l) => s + l.vatAmount);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _headerCard(d, tur),
        const SizedBox(height: AppSpacing.md),
        _ozetKart(d, brut, iskonto, kdv),
        const SizedBox(height: AppSpacing.md),
        _SectionHeader(
            ikon: Icons.format_list_bulleted_rounded,
            baslik: 'Satırlar (${d.satirlar.length})'),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < d.satirlar.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SatirKart(index: i, satir: d.satirlar[i]),
          ),
        if (d.baslik.isFaturalandi && d.baslik.invoiceRef != null) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionHeader(
              ikon: Icons.receipt_long_rounded, baslik: 'Bağlı Fatura'),
          const SizedBox(height: AppSpacing.sm),
          _BagliFaturaKart(baslik: d.baslik),
        ],
        if (d.aciklamalar.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionHeader(ikon: Icons.notes_rounded, baslik: 'Açıklama'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in d.aciklamalar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(a, style: AppTypography.bodySmall),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _headerCard(IrsaliyeDetayModel d, IrsaliyeTuru? tur) {
    final renk = tur?.renk ?? AppColors.slate500;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
                  color: renk.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tur?.ikon ?? Icons.local_shipping_rounded,
                    color: renk, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(d.baslik.trCodeName,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(DateFormat('dd MMMM yyyy', 'tr_TR')
                        .format(d.baslik.date),
                        style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _kvRow('Cari', d.baslik.clientTitle),
          if (d.baslik.clientCode.isNotEmpty)
            _kvRow('Cari Kodu', d.baslik.clientCode),
          _kvRow('Fiş No', d.baslik.ficheNo.isEmpty ? '—' : d.baslik.ficheNo),
          if (d.baslik.docCode.isNotEmpty)
            _kvRow('Belge No', d.baslik.docCode),
          if (d.baslik.isFaturalandi)
            _kvRow('Fatura',
                d.baslik.invNo.isEmpty ? 'Faturalandı' : d.baslik.invNo,
                ikon: Icons.task_alt_rounded, renk: AppColors.positive)
          else
            _kvRow('Fatura', 'Henüz faturalanmadı',
                ikon: Icons.unpublished_outlined, renk: AppColors.warning),
        ],
      ),
    );
  }

  Widget _ozetKart(IrsaliyeDetayModel d, double brut, double iskonto, double kdv) {
    final fmt = NumberFormat.currency(
        locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Net Toplam',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.slate500)),
              const Spacer(),
              Text(fmt.format(d.baslik.netTotal),
                  style: AppTypography.h2
                      .copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _miniMetric('Brüt', brut, AppColors.slate700)),
              Expanded(
                  child: _miniMetric('İskonto', iskonto,
                      iskonto > 0 ? AppColors.negative : AppColors.slate400)),
              Expanded(child: _miniMetric('KDV', kdv, AppColors.cyan)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.caption
                .copyWith(color: AppColors.slate500)),
        Text(
          NumberFormat.currency(
                  locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
              .format(value),
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _kvRow(String k, String v, {IconData? ikon, Color? renk}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(k,
                style: AppTypography.caption
                    .copyWith(color: AppColors.slate500)),
          ),
          Expanded(
            child: Row(
              children: [
                if (ikon != null) ...[
                  Icon(ikon, size: 14, color: renk ?? AppColors.slate700),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(v,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: renk ?? AppColors.slate900,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  const _SectionHeader({required this.ikon, required this.baslik});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(ikon, size: 18, color: AppColors.slate600),
          const SizedBox(width: AppSpacing.sm),
          Text(baslik, style: AppTypography.h3),
        ],
      ),
    );
  }
}

class _SatirKart extends StatelessWidget {
  final int index;
  final IrsaliyeSatirModel satir;
  const _SatirKart({required this.index, required this.satir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.slate100,
                child: Text('${index + 1}',
                    style: AppTypography.caption
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(satir.stockName.isEmpty
                        ? satir.lineDescription.isEmpty
                            ? '(satır)'
                            : satir.lineDescription
                        : satir.stockName,
                        style: AppTypography.bodySmall
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (satir.stockCode.isNotEmpty)
                      Text(satir.stockCode,
                          style: AppTypography.caption),
                  ],
                ),
              ),
              Text(
                NumberFormat.currency(
                        locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
                    .format(satir.lineNet),
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _miniLabel('Miktar',
                  '${_fmtPlain(satir.amount)} ${satir.uomCode}'),
              const SizedBox(width: AppSpacing.md),
              _miniLabel('Birim Fiyat',
                  NumberFormat.currency(
                          locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
                      .format(satir.price)),
              const SizedBox(width: AppSpacing.md),
              _miniLabel('KDV', '%${_fmtPlain(satir.vatRate)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniLabel(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k,
            style: AppTypography.caption
                .copyWith(color: AppColors.slate500)),
        Text(v,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            )),
      ],
    );
  }
}

String _fmtPlain(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}

// İrsaliyeye bağlı fatura kartı — dokununca fatura detayına gider.
class _BagliFaturaKart extends StatelessWidget {
  final IrsaliyeModel baslik;
  const _BagliFaturaKart({required this.baslik});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FaturaDetayScreen(
              fatura: FaturaModel(
                id: baslik.invoiceRef!,
                ficheNo: baslik.invNo,
                docCode: '',
                date: baslik.date,
                trCode: 0,
                trCodeName: '',
                clientRef: baslik.clientRef,
                clientCode: baslik.clientCode,
                clientTitle: baslik.clientTitle,
                netTotal: 0,
                grossTotal: 0,
                totalVat: 0,
                totalDiscounts: 0,
                cancelled: 0,
                isDraft: false,
              ),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      baslik.invNo.isEmpty ? '(Fatura no yok)' : baslik.invNo,
                      style: AppTypography.bodySmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text('Faturaya git',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.slate500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.slate400),
            ],
          ),
        ),
      ),
    );
  }
}
