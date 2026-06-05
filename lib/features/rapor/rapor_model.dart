import '../malzeme/malzeme_model.dart' show AmbarStok;

// Raporlar alanı modelleri. JSON anahtarları backend (LogoMobileApi) camelCase
// serileştirmesiyle eşleşmeli — derleyici uyuşmazlığı yakalamaz.

// ───────── 1) Cari hesap/bakiye raporu ─────────
class CariBakiyeRapor {
  final int id;
  final String code;
  final String title;
  final String city;
  final String country;
  final String phone;
  final double toplamBorc;
  final double toplamAlacak;
  final double bakiye;

  CariBakiyeRapor({
    required this.id,
    required this.code,
    required this.title,
    required this.city,
    required this.country,
    required this.phone,
    required this.toplamBorc,
    required this.toplamAlacak,
    required this.bakiye,
  });

  bool get isBorclu => bakiye > 0;
  bool get isAlacakli => bakiye < 0;

  factory CariBakiyeRapor.fromJson(Map<String, dynamic> json) {
    return CariBakiyeRapor(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      toplamBorc: (json['toplamBorc'] as num?)?.toDouble() ?? 0.0,
      toplamAlacak: (json['toplamAlacak'] as num?)?.toDouble() ?? 0.0,
      bakiye: (json['bakiye'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ───────── 2) Vade raporu ─────────
class VadeRapor {
  final int id;
  final String code;
  final String title;
  final String city;
  final String phone;
  final double toplamVadesiGecen;
  final DateTime? enEskiVadeTarihi;
  final int enEskiGunFarki;
  final int vadeSayisi;
  final double vadesi_0_30;
  final double vadesi_31_60;
  final double vadesi_61_90;
  final double vadesi_90Plus;

  VadeRapor({
    required this.id,
    required this.code,
    required this.title,
    required this.city,
    required this.phone,
    required this.toplamVadesiGecen,
    required this.enEskiVadeTarihi,
    required this.enEskiGunFarki,
    required this.vadeSayisi,
    required this.vadesi_0_30,
    required this.vadesi_31_60,
    required this.vadesi_61_90,
    required this.vadesi_90Plus,
  });

  factory VadeRapor.fromJson(Map<String, dynamic> json) {
    return VadeRapor(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      toplamVadesiGecen:
          (json['toplamVadesiGecen'] as num?)?.toDouble() ?? 0.0,
      enEskiVadeTarihi: json['enEskiVadeTarihi'] != null
          ? DateTime.parse(json['enEskiVadeTarihi'] as String)
          : null,
      enEskiGunFarki: json['enEskiGunFarki'] as int? ?? 0,
      vadeSayisi: json['vadeSayisi'] as int? ?? 0,
      vadesi_0_30: (json['vadesi_0_30'] as num?)?.toDouble() ?? 0.0,
      vadesi_31_60: (json['vadesi_31_60'] as num?)?.toDouble() ?? 0.0,
      vadesi_61_90: (json['vadesi_61_90'] as num?)?.toDouble() ?? 0.0,
      vadesi_90Plus: (json['vadesi_90Plus'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ───────── 3) Stok durum raporu ─────────
class StokRapor {
  final int id;
  final String kod;
  final String ad;
  final String aciklama;
  final String birim;
  final String tur;
  final double fiiliStok;
  final double gercekStok;

  StokRapor({
    required this.id,
    required this.kod,
    required this.ad,
    required this.aciklama,
    required this.birim,
    required this.tur,
    required this.fiiliStok,
    required this.gercekStok,
  });

  bool get stokYok => fiiliStok <= 0;

  factory StokRapor.fromJson(Map<String, dynamic> json) {
    return StokRapor(
      id: json['id'] as int,
      kod: json['kod'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      birim: json['birim'] as String? ?? '',
      tur: json['tur'] as String? ?? '',
      fiiliStok: (json['fiiliStok'] as num?)?.toDouble() ?? 0.0,
      gercekStok: (json['gercekStok'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ───────── 4) Ayrıntılı stok raporu (ambar dökümü) ─────────
class StokAmbarRapor {
  final int id;
  final String kod;
  final String ad;
  final String birim;
  final String tur;
  final double toplamFiili;
  final double toplamGercek;
  final List<AmbarStok> ambarlar;

  StokAmbarRapor({
    required this.id,
    required this.kod,
    required this.ad,
    required this.birim,
    required this.tur,
    required this.toplamFiili,
    required this.toplamGercek,
    required this.ambarlar,
  });

  factory StokAmbarRapor.fromJson(Map<String, dynamic> json) {
    final liste = (json['ambarlar'] as List<dynamic>? ?? [])
        .map((e) => AmbarStok.fromJson(e as Map<String, dynamic>))
        .toList();
    return StokAmbarRapor(
      id: json['id'] as int,
      kod: json['kod'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      birim: json['birim'] as String? ?? '',
      tur: json['tur'] as String? ?? '',
      toplamFiili: (json['toplamFiili'] as num?)?.toDouble() ?? 0.0,
      toplamGercek: (json['toplamGercek'] as num?)?.toDouble() ?? 0.0,
      ambarlar: liste,
    );
  }
}

// ───────── 5) Kritik stok raporu ─────────
class KritikStokRapor {
  final int id;
  final String kod;
  final String ad;
  final String birim;
  final double fiiliStok;
  final double asgariStok;
  final double fark;

  KritikStokRapor({
    required this.id,
    required this.kod,
    required this.ad,
    required this.birim,
    required this.fiiliStok,
    required this.asgariStok,
    required this.fark,
  });

  factory KritikStokRapor.fromJson(Map<String, dynamic> json) {
    return KritikStokRapor(
      id: json['id'] as int,
      kod: json['kod'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      birim: json['birim'] as String? ?? '',
      fiiliStok: (json['fiiliStok'] as num?)?.toDouble() ?? 0.0,
      asgariStok: (json['asgariStok'] as num?)?.toDouble() ?? 0.0,
      fark: (json['fark'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
