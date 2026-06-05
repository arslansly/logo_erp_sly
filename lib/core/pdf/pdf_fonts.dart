import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// PDF üretiminde kullanılan Inter fontlarını uygulama asset'lerinden yükler.
///
/// Önceden `PdfGoogleFonts.inter*()` ile fontlar çalışma anında Google CDN'den
/// indiriliyordu; cihaz internete (fonts.gstatic.com) ulaşamadığında indirme
/// askıda kalıyor ve PDF önizleme sonsuza dek dönüyordu. Fontlar artık
/// `assets/fonts/` altında gömülü; bu yükleyici onları offline ve hızlı sağlar.
///
/// Helvetica gibi yerleşik PDF fontları Türkçe karakterleri (ş/ğ/ı/İ) desteklemez,
/// bu yüzden Inter şart.
class PdfFonts {
  PdfFonts._();

  static pw.Font? _regular;
  static pw.Font? _semiBold;
  static pw.Font? _bold;

  /// Asset'ten tek bir font yükler (ilk yüklemeden sonra cache'lenir).
  static Future<pw.Font> _load(String asset) async {
    final data = await rootBundle.load(asset);
    return pw.Font.ttf(data);
  }

  /// Inter Regular — gövde metni.
  static Future<pw.Font> regular() async =>
      _regular ??= await _load('assets/fonts/Inter-Regular.ttf');

  /// Inter SemiBold — vurgular / başlıklar.
  static Future<pw.Font> semiBold() async =>
      _semiBold ??= await _load('assets/fonts/Inter-SemiBold.ttf');

  /// Inter Bold — kalın başlıklar.
  static Future<pw.Font> bold() async =>
      _bold ??= await _load('assets/fonts/Inter-Bold.ttf');
}
