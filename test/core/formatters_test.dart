import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logo_mobil/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  group('Formatters.currency', () {
    test('tam sayı formatı', () {
      expect(Formatters.currency(2847350.0), '₺2.847.350,00');
    });

    test('ondalıklı değer', () {
      expect(Formatters.currency(1234.56), '₺1.234,56');
    });

    test('sıfır', () {
      expect(Formatters.currency(0), '₺0,00');
    });

    test('negatif değer', () {
      expect(Formatters.currency(-500.0), '-₺500,00');
    });
  });

  group('Formatters.currencyCompact', () {
    test('milyon üzeri — Mn', () {
      expect(Formatters.currencyCompact(2800000.0), '₺2,8 Mn');
    });

    test('bin üzeri — B', () {
      expect(Formatters.currencyCompact(324500.0), '₺324,5 B');
    });

    test('bin altı', () {
      expect(Formatters.currencyCompact(750.0), '₺750');
    });

    test('negatif milyon', () {
      expect(Formatters.currencyCompact(-1500000.0), '-₺1,5 Mn');
    });

    test('negatif bin', () {
      expect(Formatters.currencyCompact(-2500.0), '-₺2,5 B');
    });

    test('sıfır', () {
      expect(Formatters.currencyCompact(0), '₺0');
    });
  });

  group('Formatters.relativeTime', () {
    test('bugün — saat gösterir', () {
      final now = DateTime.now();
      final result = Formatters.relativeTime(now);
      final expected =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      expect(result, expected);
    });

    test('dün', () {
      final dun = DateTime.now().subtract(const Duration(days: 1));
      final saat =
          '${dun.hour.toString().padLeft(2, '0')}:${dun.minute.toString().padLeft(2, '0')}';
      expect(Formatters.relativeTime(dun), 'Dün $saat');
    });

    test('3 gün önce', () {
      final uc = DateTime.now().subtract(const Duration(days: 3));
      expect(Formatters.relativeTime(uc), '3 gün önce');
    });

    test('6 gün önce', () {
      final alti = DateTime.now().subtract(const Duration(days: 6));
      expect(Formatters.relativeTime(alti), '6 gün önce');
    });

    test('7+ gün — tarih formatı', () {
      final eskiTarih = DateTime(2025, 1, 15, 10, 30);
      final result = Formatters.relativeTime(eskiTarih);
      expect(result, isNot(contains('gün önce')));
      expect(result, isNot('Dün 10:30'));
    });
  });
}
