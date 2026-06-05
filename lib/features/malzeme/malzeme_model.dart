// Malzeme türü filtresi (LG_XXX_ITEMS.CARDTYPE) — Stok ekranı filtre çipleri.
enum MalzemeTur {
  hammadde(10, 'Hammadde'),
  yariMamul(11, 'Yarı Mamul'),
  mamul(12, 'Mamul'),
  ticariMal(1, 'Ticari Mal');

  final int cardType;
  final String adi;
  const MalzemeTur(this.cardType, this.adi);
}

class AmbarStok {
  final int ambarNo;
  final String ambarAdi;
  final double fiiliStok;
  final double gercekStok;

  AmbarStok({
    required this.ambarNo,
    required this.ambarAdi,
    required this.fiiliStok,
    required this.gercekStok,
  });

  factory AmbarStok.fromJson(Map<String, dynamic> json) {
    return AmbarStok(
      ambarNo: json['ambarNo'] as int? ?? 0,
      ambarAdi: json['ambarAdi'] as String? ?? '',
      fiiliStok: (json['fiiliStok'] as num?)?.toDouble() ?? 0.0,
      gercekStok: (json['gercekStok'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Malzeme {
  final int id;
  final String kod;
  final String ad;
  final String grupKodu;
  final String birim;
  final String tur;
  final double fiiliStok;
  final double gercekStok;

  Malzeme({
    required this.id,
    required this.kod,
    required this.ad,
    required this.grupKodu,
    required this.birim,
    required this.tur,
    required this.fiiliStok,
    required this.gercekStok,
  });

  factory Malzeme.fromJson(Map<String, dynamic> json) {
    return Malzeme(
      id: json['id'] as int,
      kod: json['kod'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      grupKodu: json['grupKodu'] as String? ?? '',
      birim: json['birim'] as String? ?? '',
      tur: json['tur'] as String? ?? '',
      fiiliStok: (json['fiiliStok'] as num?)?.toDouble() ?? 0.0,
      gercekStok: (json['gercekStok'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get stokYok => fiiliStok <= 0;
  double get rezerveli => fiiliStok - gercekStok;
}

class MalzemeDetay {
  final int id;
  final String kod;
  final String ad;
  final String aciklama2;
  final String aciklama3;
  final String grupKodu;
  final String birim;
  final String tur;
  final String ozelKod1;
  final String ozelKod2;
  final String ozelKod3;
  final String ozelKod4;
  final String ozelKod5;
  final double fiiliStok;
  final double gercekStok;
  final double satinalmaFiyati;
  final String satinalmaDoviz;
  final double satisFiyati;
  final String satisDoviz;
  final double sonAlisFiyati;
  final double sonSatisFiyati;
  final List<AmbarStok> ambarStoklar;

  MalzemeDetay({
    required this.id,
    required this.kod,
    required this.ad,
    required this.aciklama2,
    required this.aciklama3,
    required this.grupKodu,
    required this.birim,
    required this.tur,
    required this.ozelKod1,
    required this.ozelKod2,
    required this.ozelKod3,
    required this.ozelKod4,
    required this.ozelKod5,
    required this.fiiliStok,
    required this.gercekStok,
    required this.satinalmaFiyati,
    required this.satinalmaDoviz,
    required this.satisFiyati,
    required this.satisDoviz,
    required this.sonAlisFiyati,
    required this.sonSatisFiyati,
    required this.ambarStoklar,
  });

  factory MalzemeDetay.fromJson(Map<String, dynamic> json) {
    final ambarlar = (json['ambarStoklar'] as List<dynamic>? ?? [])
        .map((e) => AmbarStok.fromJson(e as Map<String, dynamic>))
        .toList();
    return MalzemeDetay(
      id: json['id'] as int,
      kod: json['kod'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      aciklama2: json['aciklama2'] as String? ?? '',
      aciklama3: json['aciklama3'] as String? ?? '',
      grupKodu: json['grupKodu'] as String? ?? '',
      birim: json['birim'] as String? ?? '',
      tur: json['tur'] as String? ?? '',
      ozelKod1: json['ozelKod1'] as String? ?? '',
      ozelKod2: json['ozelKod2'] as String? ?? '',
      ozelKod3: json['ozelKod3'] as String? ?? '',
      ozelKod4: json['ozelKod4'] as String? ?? '',
      ozelKod5: json['ozelKod5'] as String? ?? '',
      fiiliStok: (json['fiiliStok'] as num?)?.toDouble() ?? 0.0,
      gercekStok: (json['gercekStok'] as num?)?.toDouble() ?? 0.0,
      satinalmaFiyati: (json['satinalmaFiyati'] as num?)?.toDouble() ?? 0.0,
      satinalmaDoviz: json['satinalmaDoviz'] as String? ?? 'TL',
      satisFiyati: (json['satisFiyati'] as num?)?.toDouble() ?? 0.0,
      satisDoviz: json['satisDoviz'] as String? ?? 'TL',
      sonAlisFiyati: (json['sonAlisFiyati'] as num?)?.toDouble() ?? 0.0,
      sonSatisFiyati: (json['sonSatisFiyati'] as num?)?.toDouble() ?? 0.0,
      ambarStoklar: ambarlar,
    );
  }

  bool get stokYok => fiiliStok <= 0;
  double get rezerveli => fiiliStok - gercekStok;
}

class MalzemeHareket {
  final int id;
  final DateTime tarih;
  final int islemTipi;
  final String islemTipiAdi;
  final String fisNo;
  final String cariAdi;
  final String aciklama;
  final double miktar;
  final double birimFiyat;
  final double tutar;
  final bool giris;
  final bool fatura;
  final String ambar;

  MalzemeHareket({
    required this.id,
    required this.tarih,
    required this.islemTipi,
    required this.islemTipiAdi,
    required this.fisNo,
    required this.cariAdi,
    required this.aciklama,
    required this.miktar,
    required this.birimFiyat,
    required this.tutar,
    required this.giris,
    required this.fatura,
    required this.ambar,
  });

  factory MalzemeHareket.fromJson(Map<String, dynamic> json) {
    return MalzemeHareket(
      id: json['id'] as int,
      tarih: DateTime.parse(json['tarih'] as String),
      islemTipi: json['islemTipi'] as int? ?? 0,
      islemTipiAdi: json['islemTipiAdi'] as String? ?? '',
      fisNo: json['fisNo'] as String? ?? '',
      cariAdi: json['cariAdi'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      miktar: (json['miktar'] as num?)?.toDouble() ?? 0.0,
      birimFiyat: (json['birimFiyat'] as num?)?.toDouble() ?? 0.0,
      tutar: (json['tutar'] as num?)?.toDouble() ?? 0.0,
      giris: json['giris'] as bool? ?? false,
      fatura: json['fatura'] as bool? ?? false,
      ambar: json['ambar'] as String? ?? '',
    );
  }
}
