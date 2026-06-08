// Patron paneli veri modelleri — backend `PatronOzet`/`BankaHesap`/`CekKayit`
// ile JSON sözleşmesini paylaşır (camelCase). Alan adları birebir eşleşmeli.

class PatronOzet {
  // ── Net alacak / borç ──
  final double toplamAlacak;
  final double toplamBorc;
  final double netBakiye;
  final int alacakliCariSayisi;
  final int borcluCariSayisi;

  // ── Yaşlandırma (vadesi geçen alacak kovaları) ──
  final double yaslandirma0_30;
  final double yaslandirma31_60;
  final double yaslandirma61_90;
  final double yaslandirma90Plus;
  final double toplamVadesiGecen;

  // ── Nakit & banka ──
  final double kasaBakiye;
  final int kasaHesapSayisi;
  final double bankaBakiye;
  final int bankaHesapSayisi;
  final double nakitToplam;

  // ── Çek / senet ──
  final double cekTahsilTutar;
  final int cekTahsilAdet;
  final double cekOdemeTutar;
  final int cekOdemeAdet;
  final double cekKarsiliksizTutar;
  final int cekKarsiliksizAdet;
  final double cekVadesiGecmis;
  final double cekBuHafta;
  final double cekBuAy;
  final double cekSonra;

  // ── Trend ──
  final double buAyNetDegisim;
  final double? trendYuzde; // null = veri yok → rozet gizlenir

  PatronOzet({
    required this.toplamAlacak,
    required this.toplamBorc,
    required this.netBakiye,
    required this.alacakliCariSayisi,
    required this.borcluCariSayisi,
    required this.yaslandirma0_30,
    required this.yaslandirma31_60,
    required this.yaslandirma61_90,
    required this.yaslandirma90Plus,
    required this.toplamVadesiGecen,
    required this.kasaBakiye,
    required this.kasaHesapSayisi,
    required this.bankaBakiye,
    required this.bankaHesapSayisi,
    required this.nakitToplam,
    required this.cekTahsilTutar,
    required this.cekTahsilAdet,
    required this.cekOdemeTutar,
    required this.cekOdemeAdet,
    required this.cekKarsiliksizTutar,
    required this.cekKarsiliksizAdet,
    required this.cekVadesiGecmis,
    required this.cekBuHafta,
    required this.cekBuAy,
    required this.cekSonra,
    required this.buAyNetDegisim,
    required this.trendYuzde,
  });

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
  static int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

  factory PatronOzet.fromJson(Map<String, dynamic> j) => PatronOzet(
        toplamAlacak: _d(j['toplamAlacak']),
        toplamBorc: _d(j['toplamBorc']),
        netBakiye: _d(j['netBakiye']),
        alacakliCariSayisi: _i(j['alacakliCariSayisi']),
        borcluCariSayisi: _i(j['borcluCariSayisi']),
        yaslandirma0_30: _d(j['yaslandirma0_30']),
        yaslandirma31_60: _d(j['yaslandirma31_60']),
        yaslandirma61_90: _d(j['yaslandirma61_90']),
        yaslandirma90Plus: _d(j['yaslandirma90Plus']),
        toplamVadesiGecen: _d(j['toplamVadesiGecen']),
        kasaBakiye: _d(j['kasaBakiye']),
        kasaHesapSayisi: _i(j['kasaHesapSayisi']),
        bankaBakiye: _d(j['bankaBakiye']),
        bankaHesapSayisi: _i(j['bankaHesapSayisi']),
        nakitToplam: _d(j['nakitToplam']),
        cekTahsilTutar: _d(j['cekTahsilTutar']),
        cekTahsilAdet: _i(j['cekTahsilAdet']),
        cekOdemeTutar: _d(j['cekOdemeTutar']),
        cekOdemeAdet: _i(j['cekOdemeAdet']),
        cekKarsiliksizTutar: _d(j['cekKarsiliksizTutar']),
        cekKarsiliksizAdet: _i(j['cekKarsiliksizAdet']),
        cekVadesiGecmis: _d(j['cekVadesiGecmis']),
        cekBuHafta: _d(j['cekBuHafta']),
        cekBuAy: _d(j['cekBuAy']),
        cekSonra: _d(j['cekSonra']),
        buAyNetDegisim: _d(j['buAyNetDegisim']),
        trendYuzde: (j['trendYuzde'] as num?)?.toDouble(),
      );
}

/// Banka (BNCARD) + hesap sayısı + toplam bakiye (drill-down 1. seviye).
class BankaKayit {
  final int id;
  final String kod;
  final String ad;
  final int hesapSayisi;
  final double bakiye;

  BankaKayit({
    required this.id,
    required this.kod,
    required this.ad,
    required this.hesapSayisi,
    required this.bakiye,
  });

  factory BankaKayit.fromJson(Map<String, dynamic> j) => BankaKayit(
        id: (j['id'] as num?)?.toInt() ?? 0,
        kod: j['kod'] as String? ?? '',
        ad: j['ad'] as String? ?? '',
        hesapSayisi: (j['hesapSayisi'] as num?)?.toInt() ?? 0,
        bakiye: (j['bakiye'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Banka hesabı (BANKACC) + döviz + bakiye (drill-down 2. seviye).
class BankaHesap {
  final int id;
  final String kod;
  final String ad;
  final double bakiye;
  final int currency;
  final String currencyKod; // "TL"/"USD"/...
  final String iban;

  BankaHesap({
    required this.id,
    required this.kod,
    required this.ad,
    required this.bakiye,
    this.currency = 0,
    this.currencyKod = '',
    this.iban = '',
  });

  factory BankaHesap.fromJson(Map<String, dynamic> j) => BankaHesap(
        id: (j['id'] as num?)?.toInt() ?? 0,
        kod: j['kod'] as String? ?? '',
        ad: j['ad'] as String? ?? '',
        bakiye: (j['bakiye'] as num?)?.toDouble() ?? 0.0,
        currency: (j['currency'] as num?)?.toInt() ?? 0,
        currencyKod: j['currencyKod'] as String? ?? '',
        iban: j['iban'] as String? ?? '',
      );
}

/// Tek çek/senet kaydı (drill-down).
class CekKayit {
  final int id;
  final int doc;
  final String tur; // "Çek" / "Senet"
  final int currStat;
  final String durum; // Türkçe durum
  final DateTime? vade;
  final double tutar;
  final String banka;
  final String kesideci;
  final String cariAd; // çekin bağlı olduğu cari (CSTRANS)

  CekKayit({
    required this.id,
    required this.doc,
    required this.tur,
    required this.currStat,
    required this.durum,
    required this.vade,
    required this.tutar,
    required this.banka,
    required this.kesideci,
    this.cariAd = '',
  });

  factory CekKayit.fromJson(Map<String, dynamic> j) => CekKayit(
        id: (j['id'] as num?)?.toInt() ?? 0,
        doc: (j['doc'] as num?)?.toInt() ?? 0,
        tur: j['tur'] as String? ?? 'Çek',
        currStat: (j['currStat'] as num?)?.toInt() ?? 0,
        durum: j['durum'] as String? ?? '',
        vade: j['vade'] != null ? DateTime.tryParse(j['vade'] as String) : null,
        tutar: (j['tutar'] as num?)?.toDouble() ?? 0.0,
        banka: j['banka'] as String? ?? '',
        kesideci: j['kesideci'] as String? ?? '',
        cariAd: j['cariAd'] as String? ?? '',
      );
}
