import 'package:flutter_test/flutter_test.dart';
import 'package:logo_mobil/features/cari/cari_hareket_model.dart';
import 'package:logo_mobil/features/cari/cari_model.dart';
import 'package:logo_mobil/features/cari/cari_vade_model.dart';

void main() {
  group('Cari.fromJson', () {
    test('tüm alanlar dolu JSON', () {
      final json = {
        'id': 42,
        'code': 'MUS001',
        'title': 'Test Müşterisi A.Ş.',
        'balance': 15000.50,
        'city': 'İstanbul',
        'phone': '0212 555 0000',
        'taxNumber': '1234567890',
        'address': 'Test Cad. No:1',
        'email': 'test@test.com',
        'country': 'Türkiye',
      };

      final cari = Cari.fromJson(json);

      expect(cari.id, 42);
      expect(cari.code, 'MUS001');
      expect(cari.title, 'Test Müşterisi A.Ş.');
      expect(cari.balance, 15000.50);
      expect(cari.city, 'İstanbul');
      expect(cari.phone, '0212 555 0000');
      expect(cari.taxNumber, '1234567890');
      expect(cari.isBorclu, isTrue);
      expect(cari.isAlacakli, isFalse);
    });

    test('null alanlar — varsayılan değerler', () {
      final json = {'id': 1, 'balance': null};

      final cari = Cari.fromJson(json);

      expect(cari.id, 1);
      expect(cari.code, '');
      expect(cari.title, '');
      expect(cari.balance, 0.0);
      expect(cari.isSifir, isTrue);
    });

    test('negatif bakiye — alacaklı', () {
      final cari = Cari.fromJson({'id': 1, 'balance': -5000.0});
      expect(cari.isAlacakli, isTrue);
      expect(cari.isBorclu, isFalse);
    });

    test('balance int olarak gönderilirse double\'a çevrilir', () {
      final cari = Cari.fromJson({'id': 1, 'balance': 1000});
      expect(cari.balance, 1000.0);
    });
  });

  group('CariHareket.fromJson', () {
    test('tam JSON', () {
      final json = {
        'id': 10,
        'date': '2025-03-15T14:30:00',
        'transactionType': 1,
        'transactionTypeName': 'Satış Faturası',
        'description': 'Test fatura',
        'debit': 2500.0,
        'credit': 0.0,
        'documentNo': 'FTR-001',
        'transactionNo': 'TRN-001',
      };

      final h = CariHareket.fromJson(json);

      expect(h.id, 10);
      expect(h.date, DateTime(2025, 3, 15, 14, 30));
      expect(h.transactionTypeName, 'Satış Faturası');
      expect(h.debit, 2500.0);
      expect(h.credit, 0.0);
      expect(h.isTahsilat, isFalse);
      expect(h.netAmount, -2500.0);
    });

    test('tahsilat — credit > 0', () {
      final json = {
        'id': 11,
        'date': '2025-03-20T09:00:00',
        'transactionType': 12,
        'transactionTypeName': 'Tahsilat',
        'description': '',
        'debit': 0.0,
        'credit': 1000.0,
        'documentNo': '',
        'transactionNo': '',
      };

      final h = CariHareket.fromJson(json);
      expect(h.isTahsilat, isTrue);
      expect(h.netAmount, 1000.0);
    });

    test('null string alanları boş string döner', () {
      final json = {
        'id': 1,
        'date': '2025-01-01T00:00:00',
        'transactionType': 1,
        'transactionTypeName': null,
        'description': null,
        'debit': null,
        'credit': null,
        'documentNo': null,
        'transactionNo': null,
      };

      final h = CariHareket.fromJson(json);
      expect(h.transactionTypeName, '');
      expect(h.description, '');
      expect(h.debit, 0.0);
      expect(h.credit, 0.0);
    });
  });

  group('CariVadeAnalizi.fromJson', () {
    test('tüm vade bucketları dolu', () {
      final json = {
        'cariId': 5,
        'vadesiGelmemis': 1000.0,
        'vadesi_0_30': 500.0,
        'vadesi_31_60': 300.0,
        'vadesi_61_90': 200.0,
        'vadesi_90Plus': 100.0,
        'enEskiVadeGunFarki': 95,
        'enEskiVadeTarihi': '2024-12-01T00:00:00',
        'sonTahsilatTarihi': '2025-01-15T00:00:00',
      };

      final v = CariVadeAnalizi.fromJson(json);

      expect(v.cariId, 5);
      expect(v.toplamVadesiGecen, 1100.0);
      expect(v.bakiye, 2100.0);
      expect(v.hasVadesiGecen, isTrue);
      expect(v.enEskiVadeGunFarki, 95);
      expect(v.enEskiVadeTarihi, DateTime(2024, 12, 1));
    });

    test('null DateTime alanları — null döner', () {
      final json = {
        'cariId': 1,
        'vadesiGelmemis': 0.0,
        'vadesi_0_30': 0.0,
        'vadesi_31_60': 0.0,
        'vadesi_61_90': 0.0,
        'vadesi_90Plus': 0.0,
        'enEskiVadeTarihi': null,
        'sonTahsilatTarihi': null,
      };

      final v = CariVadeAnalizi.fromJson(json);
      expect(v.enEskiVadeTarihi, isNull);
      expect(v.sonTahsilatTarihi, isNull);
      expect(v.hasVadesiGecen, isFalse);
    });

    test('hasVadesiGecen — sadece bir bucket doluysa true', () {
      final json = {
        'cariId': 1,
        'vadesiGelmemis': 5000.0,
        'vadesi_0_30': 0.0,
        'vadesi_31_60': 0.0,
        'vadesi_61_90': 0.0,
        'vadesi_90Plus': 250.0,
      };

      final v = CariVadeAnalizi.fromJson(json);
      expect(v.hasVadesiGecen, isTrue);
    });
  });
}
