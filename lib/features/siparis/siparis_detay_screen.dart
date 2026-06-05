import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/pdf/belge_pdf.dart';
import '../../core/pdf/belge_onizleme_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../fatura/fatura_model.dart' show BagliBelgeModel;
import '../irsaliye/irsaliye_detay_screen.dart';
import 'siparis_model.dart';
import 'siparis_service.dart';

class SiparisDetayScreen extends StatefulWidget {
  final int id;
  const SiparisDetayScreen({super.key, required this.id});

  @override
  State<SiparisDetayScreen> createState() => _SiparisDetayScreenState();
}

class _SiparisDetayScreenState extends State<SiparisDetayScreen> {
  SiparisDetayModel? _detay;
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
      final d = await siparisService.getDetay(widget.id);
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
        title: const Text('Sipariş Detayı'),
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

  BelgePdfData _pdfData(SiparisDetayModel d) {
    final b = d.baslik;
    final brut = d.satirlar.fold<double>(0, (s, l) => s + l.total);
    final iskonto = d.satirlar.fold<double>(0, (s, l) => s + l.discount);
    final kdv = d.satirlar.fold<double>(0, (s, l) => s + l.vatAmount);
    final ek = <String, String>{};
    if (b.durum != null) ek['Durum'] = b.durum!.adi;
    if (d.irsaliyeler.isNotEmpty) {
      ek['İrsaliye'] =
          d.irsaliyeler.map((i) => i.ficheNo).where((s) => s.isNotEmpty).join(', ');
    }
    return BelgePdfData(
      belgeBasligi: b.trCodeName.isEmpty ? 'Sipariş' : b.trCodeName,
      durumEtiketi: b.durum?.adi,
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
      dosyaAdi: 'Siparis_${b.ficheNo.isEmpty ? b.id : b.ficheNo}',
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
    final durum = d.baslik.durum;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _headerCard(d, tur, durum),
        const SizedBox(height: AppSpacing.md),
        _ozetKart(d),
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
        if (d.irsaliyeler.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionHeader(
              ikon: Icons.local_shipping_rounded,
              baslik: 'Bağlı İrsaliyeler (${d.irsaliyeler.length})'),
          const SizedBox(height: AppSpacing.sm),
          for (final b in d.irsaliyeler)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _BagliIrsaliyeKart(belge: b),
            ),
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

  Widget _headerCard(SiparisDetayModel d, SiparisTuru? tur, SiparisDurumu? durum) {
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
                child: Icon(tur?.ikon ?? Icons.assignment_rounded,
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
          _kvRow('Durum', d.baslik.durumEtiketi,
              ikon: d.baslik.durumIkon, renk: d.baslik.durumRenk),
          if (durum != null && d.baslik.sevkDurumu != SiparisSevkDurumu.ham)
            _kvRow('Onay Durumu', durum.adi,
                ikon: durum.ikon, renk: durum.renk),
        ],
      ),
    );
  }

  Widget _ozetKart(SiparisDetayModel d) {
    final toplamSiparis =
        d.satirlar.fold<double>(0, (s, l) => s + l.amount);
    // Kapanış-duyarlı: kapalı satır tamamı sevkedilmiş sayılır.
    final toplamSevk =
        d.satirlar.fold<double>(0, (s, l) => s + l.etkinSevk);
    final bekleyen =
        d.satirlar.fold<double>(0, (s, l) => s + l.bekleyenMiktar);
    final oran = toplamSiparis == 0
        ? 0.0
        : (toplamSevk / toplamSiparis).clamp(0, 1).toDouble();

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
              Text('Net Toplam',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.slate500)),
              const Spacer(),
              Text(
                NumberFormat.currency(
                        locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
                    .format(d.baslik.netTotal),
                style: AppTypography.h2
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _miniMetric('Sipariş', toplamSiparis, AppColors.accent),
              ),
              Expanded(
                child: _miniMetric('Sevkedildi', toplamSevk, AppColors.positive),
              ),
              Expanded(
                child: _miniMetric('Bekleyen', bekleyen.toDouble(),
                    bekleyen > 0 ? AppColors.warning : AppColors.slate400),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: oran,
              minHeight: 8,
              backgroundColor: AppColors.slate100,
              color: oran >= 1 ? AppColors.positive : AppColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text('Sevk oranı: %${(oran * 100).toStringAsFixed(0)}',
              style: AppTypography.caption
                  .copyWith(color: AppColors.slate500)),
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
        Text(value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2),
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            )),
      ],
    );
  }

  Widget _kvRow(String k, String v,
      {IconData? ikon, Color? renk}) {
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
  final SiparisSatirModel satir;
  const _SatirKart({required this.index, required this.satir});

  @override
  Widget build(BuildContext context) {
    final bekleyen = satir.bekleyenMiktar;
    final sevkOrani = satir.sevkOrani;

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
              _miniLabel('Sevk',
                  '${_fmtPlain(satir.etkinSevk)} ${satir.uomCode}'),
              const SizedBox(width: AppSpacing.md),
              _miniLabel(
                'Bekleyen',
                '${_fmtPlain(bekleyen.toDouble())} ${satir.uomCode}',
                color: bekleyen > 0 ? AppColors.warning : AppColors.slate500,
              ),
            ],
          ),
          if (satir.dueDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event_rounded,
                    size: 12, color: AppColors.slate500),
                const SizedBox(width: 4),
                Text(
                    'Termin: ${DateFormat('dd.MM.yyyy').format(satir.dueDate!)}',
                    style: AppTypography.caption),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: sevkOrani,
              minHeight: 4,
              backgroundColor: AppColors.slate100,
              color: sevkOrani >= 1 ? AppColors.positive : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniLabel(String k, String v, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k,
            style: AppTypography.caption
                .copyWith(color: AppColors.slate500)),
        Text(v,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.slate900,
            )),
      ],
    );
  }
}

String _fmtPlain(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}

// Siparişe bağlı irsaliye kartı — dokununca irsaliye detayına gider.
class _BagliIrsaliyeKart extends StatelessWidget {
  final BagliBelgeModel belge;
  const _BagliIrsaliyeKart({required this.belge});

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
            builder: (_) => IrsaliyeDetayScreen(id: belge.id),
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
                  color: AppColors.positive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: AppColors.positive, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      belge.ficheNo.isEmpty ? '(Fiş no yok)' : belge.ficheNo,
                      style: AppTypography.bodySmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${belge.trCodeName} · ${DateFormat('dd.MM.yyyy').format(belge.date)}',
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                NumberFormat.currency(
                        locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
                    .format(belge.total),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.slate400),
            ],
          ),
        ),
      ),
    );
  }
}
