import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/cari/cari_ekstre_model.dart';
import '../../features/cari/cari_model.dart';
import '../../features/malzeme/malzeme_model.dart';
import '../pdf/pdf_fonts.dart';

// PDF için Türkçe karakter destekli font + renkleri tek noktada tutar.
class _PdfTheme {
  final pw.Font regular;
  final pw.Font bold;

  _PdfTheme({required this.regular, required this.bold});

  static Future<_PdfTheme> load() async {
    // Inter fontları gömülü asset'ten yüklenir (internet gerekmez).
    // Eskiden PdfGoogleFonts ile CDN'den indiriliyordu ve cihaz çevrimdışıyken
    // önizleme sonsuza dek dönüyordu.
    final regular = await PdfFonts.regular();
    final bold = await PdfFonts.bold();
    return _PdfTheme(regular: regular, bold: bold);
  }

  pw.TextStyle text({double size = 9, PdfColor? color, bool boldStyle = false}) =>
      pw.TextStyle(
        font: boldStyle ? bold : regular,
        fontSize: size,
        color: color ?? PdfColors.grey900,
      );
}

// ────────── Renkler ──────────
const _primary = PdfColor.fromInt(0xFF4F46E5); // indigo
const _slate100 = PdfColor.fromInt(0xFFF1F5F9);
const _slate200 = PdfColor.fromInt(0xFFE2E8F0);
const _slate500 = PdfColor.fromInt(0xFF64748B);
const _slate700 = PdfColor.fromInt(0xFF334155);
const _positive = PdfColor.fromInt(0xFF16A34A);
const _negative = PdfColor.fromInt(0xFFDC2626);

final _tarihFmt = DateFormat('d MMM yyyy', 'tr_TR');
final _paraFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2);
final _sayiFmt = NumberFormat.decimalPattern('tr_TR');

String _money(double v) => _paraFmt.format(v).trim();

// ═══════════════════════════════════════════════════════════════════
// CARİ EKSTRE PDF
// ═══════════════════════════════════════════════════════════════════
Future<Uint8List> buildCariEkstrePdf({
  required Cari cari,
  required CariEkstre ekstre,
}) async {
  final theme = await _PdfTheme.load();
  final doc = pw.Document(
    title: 'Cari Ekstre - ${cari.title}',
    author: 'Logo Mobil',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => _pdfHeader(
        theme,
        title: 'Cari Hesap Ekstresi',
        subtitle: cari.title,
        period:
            '${_tarihFmt.format(ekstre.baslangicTarihi)} – ${_tarihFmt.format(ekstre.bitisTarihi)}',
      ),
      footer: (ctx) => _pdfFooter(theme, ctx),
      build: (ctx) => [
        _cariInfoCard(theme, cari),
        pw.SizedBox(height: 12),
        _ozetCard(theme, [
          ('Devir Bakiyesi', ekstre.devirBakiyesi),
          ('Toplam Borç', ekstre.toplamBorc),
          ('Toplam Alacak', ekstre.toplamAlacak),
          ('Kapanış Bakiyesi', ekstre.kapanisBakiyesi),
        ]),
        pw.SizedBox(height: 14),
        _ekstreTable(theme, ekstre),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _cariInfoCard(_PdfTheme th, Cari cari) {
  pw.Widget row(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 80,
              child: pw.Text(k, style: th.text(size: 9, color: _slate500)),
            ),
            pw.Expanded(
              child: pw.Text(v, style: th.text(size: 9, color: _slate700)),
            ),
          ],
        ),
      );

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _slate100,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              row('Cari Kodu', cari.code),
              row('Ünvan', cari.title),
              if (cari.taxNumber.isNotEmpty) row('Vergi No', cari.taxNumber),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (cari.phone.isNotEmpty) row('Telefon', cari.phone),
              if (cari.email.isNotEmpty) row('E-posta', cari.email),
              if (cari.city.isNotEmpty)
                row('Şehir', [cari.city, cari.country].where((s) => s.isNotEmpty).join(' / ')),
              if (cari.address.isNotEmpty) row('Adres', cari.address),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _ozetCard(_PdfTheme th, List<(String, double)> items) {
  return pw.Row(
    children: [
      for (var i = 0; i < items.length; i++) ...[
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _slate200, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(items[i].$1,
                    style: th.text(size: 8, color: _slate500)),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${_money(items[i].$2)} TL',
                  style: th.text(
                    size: 11,
                    boldStyle: true,
                    color: items[i].$2 >= 0 ? _slate700 : _negative,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (i != items.length - 1) pw.SizedBox(width: 6),
      ],
    ],
  );
}

pw.Widget _ekstreTable(_PdfTheme th, CariEkstre e) {
  final headerStyle = th.text(size: 9, boldStyle: true, color: PdfColors.white);
  final bodyStyle = th.text(size: 8.5, color: _slate700);

  pw.Widget cell(String text, pw.TextStyle style,
          {pw.Alignment align = pw.Alignment.centerLeft}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Align(
          alignment: align,
          child: pw.Text(text, style: style),
        ),
      );

  return pw.Table(
    border: pw.TableBorder.symmetric(
      inside: pw.BorderSide(color: _slate200, width: 0.4),
    ),
    columnWidths: const {
      0: pw.FixedColumnWidth(60),
      1: pw.FlexColumnWidth(2),
      2: pw.FlexColumnWidth(3),
      3: pw.FixedColumnWidth(70),
      4: pw.FixedColumnWidth(70),
      5: pw.FixedColumnWidth(80),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _primary),
        children: [
          cell('Tarih', headerStyle),
          cell('İşlem', headerStyle),
          cell('Açıklama / Belge', headerStyle),
          cell('Borç', headerStyle, align: pw.Alignment.centerRight),
          cell('Alacak', headerStyle, align: pw.Alignment.centerRight),
          cell('Bakiye', headerStyle, align: pw.Alignment.centerRight),
        ],
      ),
      ...e.hareketler.map(
        (s) => pw.TableRow(
          children: [
            cell(_tarihFmt.format(s.tarih), bodyStyle),
            cell(s.islemTipiAdi, bodyStyle),
            cell(
              [s.aciklama, s.documentNo].where((x) => x.isNotEmpty).join(' · '),
              bodyStyle,
            ),
            cell(s.borc > 0 ? _money(s.borc) : '', bodyStyle,
                align: pw.Alignment.centerRight),
            cell(s.alacak > 0 ? _money(s.alacak) : '', bodyStyle,
                align: pw.Alignment.centerRight),
            cell(_money(s.yurutulenBakiye),
                th.text(size: 8.5, boldStyle: true, color: _slate700),
                align: pw.Alignment.centerRight),
          ],
        ),
      ),
      // Toplam satırı
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _slate100),
        children: [
          cell('', bodyStyle),
          cell('', bodyStyle),
          cell('TOPLAM',
              th.text(size: 9, boldStyle: true, color: _slate700),
              align: pw.Alignment.centerRight),
          cell(_money(e.toplamBorc),
              th.text(size: 9, boldStyle: true, color: _positive),
              align: pw.Alignment.centerRight),
          cell(_money(e.toplamAlacak),
              th.text(size: 9, boldStyle: true, color: _negative),
              align: pw.Alignment.centerRight),
          cell(_money(e.kapanisBakiyesi),
              th.text(size: 9, boldStyle: true, color: _slate700),
              align: pw.Alignment.centerRight),
        ],
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
// MALZEME EKSTRE PDF
// ═══════════════════════════════════════════════════════════════════
Future<Uint8List> buildMalzemeEkstrePdf({
  required int malzemeId,
  required String malzemeAdi,
  required String birim,
  required List<MalzemeHareket> hareketler,
  DateTime? baslangic,
  DateTime? bitis,
}) async {
  final theme = await _PdfTheme.load();
  final doc = pw.Document(
    title: 'Malzeme Ekstresi - $malzemeAdi',
    author: 'Logo Mobil',
  );

  // Özet hesapla
  double toplamGiris = 0;
  double toplamCikis = 0;
  double toplamTutar = 0;
  for (final h in hareketler) {
    if (h.giris) {
      toplamGiris += h.miktar;
    } else {
      toplamCikis += h.miktar;
    }
    toplamTutar += h.tutar;
  }

  final periodLabel = (baslangic != null && bitis != null)
      ? '${_tarihFmt.format(baslangic)} – ${_tarihFmt.format(bitis)}'
      : 'Tüm tarihler';

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => _pdfHeader(
        theme,
        title: 'Malzeme Ekstresi',
        subtitle: malzemeAdi,
        period: periodLabel,
      ),
      footer: (ctx) => _pdfFooter(theme, ctx),
      build: (ctx) => [
        _malzemeOzet(theme, toplamGiris, toplamCikis, toplamTutar, birim),
        pw.SizedBox(height: 12),
        _malzemeTable(theme, hareketler, birim),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _malzemeOzet(
    _PdfTheme th, double giris, double cikis, double tutar, String birim) {
  pw.Widget kart(String label, String value, PdfColor color) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _slate200, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: th.text(size: 8, color: _slate500)),
              pw.SizedBox(height: 4),
              pw.Text(value,
                  style: th.text(size: 11, boldStyle: true, color: color)),
            ],
          ),
        ),
      );

  return pw.Row(
    children: [
      kart('Toplam Giriş', '${_sayiFmt.format(giris)} $birim', _positive),
      pw.SizedBox(width: 6),
      kart('Toplam Çıkış', '${_sayiFmt.format(cikis)} $birim', _negative),
      pw.SizedBox(width: 6),
      kart('Net Stok', '${_sayiFmt.format(giris - cikis)} $birim', _slate700),
      pw.SizedBox(width: 6),
      kart('Toplam Tutar', '${_money(tutar)} TL', _slate700),
    ],
  );
}

pw.Widget _malzemeTable(
    _PdfTheme th, List<MalzemeHareket> hareketler, String birim) {
  final headerStyle = th.text(size: 9, boldStyle: true, color: PdfColors.white);
  final bodyStyle = th.text(size: 8.5, color: _slate700);

  pw.Widget cell(String text, pw.TextStyle style,
          {pw.Alignment align = pw.Alignment.centerLeft}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Align(alignment: align, child: pw.Text(text, style: style)),
      );

  return pw.Table(
    border: pw.TableBorder.symmetric(
      inside: pw.BorderSide(color: _slate200, width: 0.4),
    ),
    columnWidths: const {
      0: pw.FixedColumnWidth(55),
      1: pw.FlexColumnWidth(2),
      2: pw.FlexColumnWidth(2),
      3: pw.FlexColumnWidth(2.5),
      4: pw.FixedColumnWidth(60),
      5: pw.FixedColumnWidth(70),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _primary),
        children: [
          cell('Tarih', headerStyle),
          cell('İşlem / Fiş', headerStyle),
          cell('Ambar', headerStyle),
          cell('Cari / Açıklama', headerStyle),
          cell('Miktar', headerStyle, align: pw.Alignment.centerRight),
          cell('Tutar', headerStyle, align: pw.Alignment.centerRight),
        ],
      ),
      ...hareketler.map((h) {
        final isaret = h.giris ? '+' : '−';
        final renk = h.giris ? _positive : _negative;
        return pw.TableRow(
          children: [
            cell(_tarihFmt.format(h.tarih), bodyStyle),
            cell(
              [h.islemTipiAdi, if (h.fisNo.isNotEmpty) h.fisNo].join('\n'),
              bodyStyle,
            ),
            cell(h.ambar, bodyStyle),
            cell(
              [h.cariAdi, if (h.aciklama.isNotEmpty) h.aciklama]
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              bodyStyle,
            ),
            cell('$isaret${_sayiFmt.format(h.miktar)} $birim',
                th.text(size: 8.5, boldStyle: true, color: renk),
                align: pw.Alignment.centerRight),
            cell(h.tutar > 0 ? _money(h.tutar) : '', bodyStyle,
                align: pw.Alignment.centerRight),
          ],
        );
      }),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
// GENEL TABLO RAPORU PDF (Raporlar alanı — tüm raporlar bunu kullanır)
// ═══════════════════════════════════════════════════════════════════
/// Başlık + opsiyonel özet kartları + tablo yapısındaki herhangi bir raporu PDF'e döker.
/// [kolonlar] tablo başlıkları, [satirlar] her biri kolon sayısı kadar metin içeren satırlar.
/// [sagKolonlar] sağa yaslanacak kolon indeksleri (sayısal değerler için).
/// [genislikler] kolon esneklik ağırlıkları (verilmezse tüm kolonlar eşit).
/// [ozetler] tablonun üstünde gösterilecek (etiket, değer) özet kartları.
Future<Uint8List> buildTabloRaporPdf({
  required String baslik,
  String altBilgi = '',
  required List<String> kolonlar,
  required List<List<String>> satirlar,
  Set<int> sagKolonlar = const {},
  List<double>? genislikler,
  List<(String, String)> ozetler = const [],
}) async {
  final theme = await _PdfTheme.load();
  final doc = pw.Document(title: baslik, author: 'Logo Mobil');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      // Varsayılan limit 20 sayfa; büyük stok/cari raporları bunu aşar.
      maxPages: 100000,
      header: (ctx) => _raporHeader(theme, baslik, altBilgi, satirlar.length),
      footer: (ctx) => _pdfFooter(theme, ctx),
      build: (ctx) => [
        if (ozetler.isNotEmpty) ...[
          _raporOzetCard(theme, ozetler),
          pw.SizedBox(height: 12),
        ],
        _raporTable(theme, kolonlar, satirlar, sagKolonlar, genislikler),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _raporHeader(_PdfTheme th, String baslik, String altBilgi, int adet) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 10),
    margin: const pw.EdgeInsets.only(bottom: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _slate200, width: 0.8)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(baslik,
                  style: th.text(size: 16, boldStyle: true, color: _primary)),
              if (altBilgi.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(altBilgi, style: th.text(size: 9, color: _slate700)),
              ],
              pw.SizedBox(height: 2),
              pw.Text('$adet kayıt', style: th.text(size: 9, color: _slate500)),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Logo Mobil',
                style: th.text(size: 10, boldStyle: true, color: _slate700)),
            pw.SizedBox(height: 2),
            pw.Text(
              'Oluşturma: ${DateFormat('d MMM yyyy HH:mm', 'tr_TR').format(DateTime.now())}',
              style: th.text(size: 8, color: _slate500),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _raporOzetCard(_PdfTheme th, List<(String, String)> items) {
  return pw.Row(
    children: [
      for (var i = 0; i < items.length; i++) ...[
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _slate200, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(items[i].$1, style: th.text(size: 8, color: _slate500)),
                pw.SizedBox(height: 4),
                pw.Text(items[i].$2,
                    style: th.text(size: 11, boldStyle: true, color: _slate700)),
              ],
            ),
          ),
        ),
        if (i != items.length - 1) pw.SizedBox(width: 6),
      ],
    ],
  );
}

pw.Widget _raporTable(
  _PdfTheme th,
  List<String> kolonlar,
  List<List<String>> satirlar,
  Set<int> sagKolonlar,
  List<double>? genislikler,
) {
  final headerStyle = th.text(size: 9, boldStyle: true, color: PdfColors.white);
  final bodyStyle = th.text(size: 8.5, color: _slate700);

  pw.Widget cell(String text, pw.TextStyle style, int col) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Align(
          alignment: sagKolonlar.contains(col)
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
          child: pw.Text(text, style: style),
        ),
      );

  final widths = <int, pw.TableColumnWidth>{};
  if (genislikler != null) {
    for (var i = 0; i < genislikler.length; i++) {
      widths[i] = pw.FlexColumnWidth(genislikler[i]);
    }
  }

  return pw.Table(
    border: pw.TableBorder.symmetric(
      inside: pw.BorderSide(color: _slate200, width: 0.4),
    ),
    columnWidths: widths,
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _primary),
        children: [
          for (var c = 0; c < kolonlar.length; c++)
            cell(kolonlar[c], headerStyle, c),
        ],
      ),
      ...satirlar.map(
        (satir) => pw.TableRow(
          children: [
            for (var c = 0; c < satir.length; c++) cell(satir[c], bodyStyle, c),
          ],
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
// ORTAK HEADER/FOOTER
// ═══════════════════════════════════════════════════════════════════
pw.Widget _pdfHeader(
  _PdfTheme th, {
  required String title,
  required String subtitle,
  required String period,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 10),
    margin: const pw.EdgeInsets.only(bottom: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _slate200, width: 0.8)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title,
                  style: th.text(size: 16, boldStyle: true, color: _primary)),
              pw.SizedBox(height: 4),
              pw.Text(subtitle,
                  style: th.text(size: 11, color: _slate700, boldStyle: true)),
              pw.SizedBox(height: 2),
              pw.Text('Dönem: $period',
                  style: th.text(size: 9, color: _slate500)),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Logo Mobil',
                style: th.text(size: 10, boldStyle: true, color: _slate700)),
            pw.SizedBox(height: 2),
            pw.Text(
              'Oluşturma: ${DateFormat('d MMM yyyy HH:mm', 'tr_TR').format(DateTime.now())}',
              style: th.text(size: 8, color: _slate500),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _pdfFooter(_PdfTheme th, pw.Context ctx) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    padding: const pw.EdgeInsets.only(top: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _slate200, width: 0.4)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Logo Mobil • Otomatik üretilmiştir',
            style: th.text(size: 8, color: _slate500)),
        pw.Text('Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: th.text(size: 8, color: _slate500)),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// PAYLAŞMA YARDIMCISI (printing paketinden Share API)
// ═══════════════════════════════════════════════════════════════════
Future<void> sharePdf(Uint8List bytes, String filename) async {
  await Printing.sharePdf(bytes: bytes, filename: filename);
}
