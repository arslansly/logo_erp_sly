import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_fonts.dart';

/// Fatura / sipariş / irsaliye için ortak, paylaşılabilir belge görseli (PDF).
/// e-Fatura/e-İrsaliye değildir — müşteriye iletmek için basit bir önizleme çıktısıdır.

class BelgePdfSatir {
  final int sira;
  final String kod;
  final String ad;
  final double miktar;
  final String birim;
  final double fiyat;
  final double kdvOran;
  final double tutar; // satır net (KDV dahil)

  BelgePdfSatir({
    required this.sira,
    required this.kod,
    required this.ad,
    required this.miktar,
    required this.birim,
    required this.fiyat,
    required this.kdvOran,
    required this.tutar,
  });
}

class BelgePdfData {
  final String firmaAdi;
  final String belgeBasligi; // örn. "TOPTAN SATIŞ İRSALİYESİ"
  final String? durumEtiketi; // örn. "TASLAK", "Aktarıldı", "Sevkedilebilir"
  final String fisNo;
  final String belgeNo;
  final DateTime tarih;
  final String cariUnvan;
  final String cariKod;
  final List<BelgePdfSatir> satirlar;
  final double brut;
  final double iskonto;
  final double kdv;
  final double net;
  final String paraSembol; // ₺ / $ / €
  final List<String> aciklamalar;
  final Map<String, String> ekBilgiler; // Termin, Ambar, Taşıyıcı, Durum vb.
  final String dosyaAdi;

  BelgePdfData({
    this.firmaAdi = 'LOGO Mobil',
    required this.belgeBasligi,
    this.durumEtiketi,
    required this.fisNo,
    required this.belgeNo,
    required this.tarih,
    required this.cariUnvan,
    required this.cariKod,
    required this.satirlar,
    required this.brut,
    required this.iskonto,
    required this.kdv,
    required this.net,
    this.paraSembol = '₺',
    this.aciklamalar = const [],
    this.ekBilgiler = const {},
    required this.dosyaAdi,
  });
}

// Tema renkleri (AppColors ile uyumlu)
const _accent = PdfColor.fromInt(0xFF2563EB);
const _slate900 = PdfColor.fromInt(0xFF0F172A);
const _slate600 = PdfColor.fromInt(0xFF475569);
const _slate400 = PdfColor.fromInt(0xFF94A3B8);
const _slate200 = PdfColor.fromInt(0xFFE2E8F0);
const _slate100 = PdfColor.fromInt(0xFFF1F5F9);
const _slate50 = PdfColor.fromInt(0xFFF8FAFC);

Future<Uint8List> belgePdfOlustur(BelgePdfData d) async {
  final doc = pw.Document();
  // Türkçe karakter desteği için Inter (Helvetica ş/ğ/ı destekemez).
  // Gömülü asset'ten yüklenir — internet gerekmez.
  final regular = await PdfFonts.regular();
  final bold = await PdfFonts.semiBold();
  final theme = pw.ThemeData.withFont(base: regular, bold: bold);

  final para = NumberFormat.currency(
      locale: 'tr_TR', symbol: d.paraSembol, decimalDigits: 2);
  String fmtMiktar(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 36),
      ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Sayfa ${ctx.pageNumber}/${ctx.pagesCount}  •  Bu belge bilgilendirme amaçlıdır, resmi e-belge değildir.',
          style: const pw.TextStyle(fontSize: 7, color: _slate400),
        ),
      ),
      build: (ctx) => [
        _header(d),
        pw.SizedBox(height: 16),
        _infoSection(d, para),
        pw.SizedBox(height: 14),
        _satirTablosu(d, para, fmtMiktar),
        pw.SizedBox(height: 12),
        _toplamlar(d, para),
        if (d.aciklamalar.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _aciklamalar(d),
        ],
      ],
    ),
  );

  return doc.save();
}

pw.Widget _header(BelgePdfData d) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(d.firmaAdi,
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold, color: _accent)),
          pw.SizedBox(height: 2),
          pw.Text(d.belgeBasligi,
              style: const pw.TextStyle(fontSize: 11, color: _slate600)),
        ],
      ),
      if (d.durumEtiketi != null && d.durumEtiketi!.isNotEmpty)
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: pw.BoxDecoration(
            color: _accent,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(d.durumEtiketi!.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
        ),
    ],
  );
}

pw.Widget _infoSection(BelgePdfData d, NumberFormat para) {
  pw.Widget kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 70,
              child: pw.Text(k,
                  style: const pw.TextStyle(fontSize: 9, color: _slate400)),
            ),
            pw.Expanded(
              child: pw.Text(v,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _slate900)),
            ),
          ],
        ),
      );

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _slate50,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: _slate200),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Cari
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CARİ',
                  style: const pw.TextStyle(fontSize: 8, color: _slate400)),
              pw.SizedBox(height: 2),
              pw.Text(d.cariUnvan.isEmpty ? '—' : d.cariUnvan,
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _slate900)),
              if (d.cariKod.isNotEmpty)
                pw.Text(d.cariKod,
                    style: const pw.TextStyle(fontSize: 9, color: _slate600)),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        // Fiş bilgileri
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              kv('Tarih', DateFormat('dd.MM.yyyy').format(d.tarih)),
              kv('Fiş No', d.fisNo.isEmpty ? '—' : d.fisNo),
              if (d.belgeNo.isNotEmpty) kv('Belge No', d.belgeNo),
              ...d.ekBilgiler.entries.map((e) => kv(e.key, e.value)),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _satirTablosu(
    BelgePdfData d, NumberFormat para, String Function(double) fmtMiktar) {
  pw.Widget hcell(String t, {pw.Alignment align = pw.Alignment.centerLeft}) =>
      pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white)),
      );

  pw.Widget cell(String t,
          {pw.Alignment align = pw.Alignment.centerLeft, bool bold = false}) =>
      pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: _slate900)),
      );

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: _accent),
      children: [
        hcell('#', align: pw.Alignment.center),
        hcell('Malzeme / Hizmet'),
        hcell('Miktar', align: pw.Alignment.centerRight),
        hcell('Fiyat', align: pw.Alignment.centerRight),
        hcell('KDV', align: pw.Alignment.center),
        hcell('Tutar', align: pw.Alignment.centerRight),
      ],
    ),
  ];

  for (var i = 0; i < d.satirlar.length; i++) {
    final s = d.satirlar[i];
    rows.add(pw.TableRow(
      decoration: pw.BoxDecoration(
        color: i.isEven ? PdfColors.white : _slate50,
      ),
      children: [
        cell('${s.sira}', align: pw.Alignment.center),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(s.ad.isEmpty ? '(satır)' : s.ad,
                  style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _slate900)),
              if (s.kod.isNotEmpty)
                pw.Text(s.kod,
                    style: const pw.TextStyle(fontSize: 7, color: _slate400)),
            ],
          ),
        ),
        cell('${fmtMiktar(s.miktar)} ${s.birim}',
            align: pw.Alignment.centerRight),
        cell(para.format(s.fiyat), align: pw.Alignment.centerRight),
        cell('%${fmtMiktar(s.kdvOran)}', align: pw.Alignment.center),
        cell(para.format(s.tutar),
            align: pw.Alignment.centerRight, bold: true),
      ],
    ));
  }

  return pw.Table(
    border: pw.TableBorder.all(color: _slate200, width: 0.5),
    columnWidths: {
      0: const pw.FixedColumnWidth(24),
      1: const pw.FlexColumnWidth(4),
      2: const pw.FlexColumnWidth(1.6),
      3: const pw.FlexColumnWidth(1.6),
      4: const pw.FixedColumnWidth(36),
      5: const pw.FlexColumnWidth(1.8),
    },
    children: rows,
  );
}

pw.Widget _toplamlar(BelgePdfData d, NumberFormat para) {
  pw.Widget satir(String k, double v, {bool bold = false, bool neg = false}) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(k,
                style: pw.TextStyle(
                    fontSize: bold ? 11 : 9,
                    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: bold ? _slate900 : _slate600)),
            pw.Text('${neg && v > 0 ? '-' : ''}${para.format(v)}',
                style: pw.TextStyle(
                    fontSize: bold ? 12 : 9,
                    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: bold ? _accent : _slate900)),
          ],
        ),
      );

  return pw.Row(
    children: [
      pw.Spacer(flex: 3),
      pw.Expanded(
        flex: 4,
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _slate100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              satir('Brüt Toplam', d.brut),
              if (d.iskonto > 0) satir('İskonto', d.iskonto, neg: true),
              satir('KDV', d.kdv),
              pw.Divider(color: _slate200, height: 10),
              satir('GENEL TOPLAM', d.net, bold: true),
            ],
          ),
        ),
      ),
    ],
  );
}

pw.Widget _aciklamalar(BelgePdfData d) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: _slate50,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: _slate200),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('AÇIKLAMA',
            style: const pw.TextStyle(fontSize: 8, color: _slate400)),
        pw.SizedBox(height: 3),
        ...d.aciklamalar.map((a) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(a,
                  style: const pw.TextStyle(fontSize: 9, color: _slate900)),
            )),
      ],
    ),
  );
}
