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

// ───────── 6) Satış performans / ciro raporu ─────────
class SatisPerformansRapor {
  final double toplamCiro;
  final int faturaSayisi;
  final double ortalamaFatura;
  final List<AylikCiro> aylikTrend;
  final List<SatisciPerformans> satiscilar;
  final List<MusteriCiro> topMusteriler;

  SatisPerformansRapor({
    required this.toplamCiro,
    required this.faturaSayisi,
    required this.ortalamaFatura,
    required this.aylikTrend,
    required this.satiscilar,
    required this.topMusteriler,
  });

  bool get bos => faturaSayisi == 0 && aylikTrend.isEmpty;

  factory SatisPerformansRapor.fromJson(Map<String, dynamic> json) {
    List<T> liste<T>(String key, T Function(Map<String, dynamic>) f) =>
        ((json[key] as List<dynamic>?) ?? const [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();
    return SatisPerformansRapor(
      toplamCiro: (json['toplamCiro'] as num?)?.toDouble() ?? 0.0,
      faturaSayisi: (json['faturaSayisi'] as num?)?.toInt() ?? 0,
      ortalamaFatura: (json['ortalamaFatura'] as num?)?.toDouble() ?? 0.0,
      aylikTrend: liste('aylikTrend', AylikCiro.fromJson),
      satiscilar: liste('satiscilar', SatisciPerformans.fromJson),
      topMusteriler: liste('topMusteriler', MusteriCiro.fromJson),
    );
  }
}

class AylikCiro {
  final int yil;
  final int ay;
  final double ciro;
  final int adet;

  AylikCiro({
    required this.yil,
    required this.ay,
    required this.ciro,
    required this.adet,
  });

  // Kısa ay etiketi (grafik altı): "Oca 24" gibi.
  static const _aylar = [
    '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ];
  String get ayKisa => (ay >= 1 && ay <= 12) ? _aylar[ay] : '';
  String get etiket => '$ayKisa ${(yil % 100).toString().padLeft(2, '0')}';

  factory AylikCiro.fromJson(Map<String, dynamic> json) => AylikCiro(
        yil: (json['yil'] as num?)?.toInt() ?? 0,
        ay: (json['ay'] as num?)?.toInt() ?? 0,
        ciro: (json['ciro'] as num?)?.toDouble() ?? 0.0,
        adet: (json['adet'] as num?)?.toInt() ?? 0,
      );
}

class SatisciPerformans {
  final int id;
  final String kod;
  final String ad;
  final double ciro;
  final int adet;

  SatisciPerformans({
    required this.id,
    required this.kod,
    required this.ad,
    required this.ciro,
    required this.adet,
  });

  factory SatisciPerformans.fromJson(Map<String, dynamic> json) =>
      SatisciPerformans(
        id: (json['id'] as num?)?.toInt() ?? 0,
        kod: json['kod'] as String? ?? '',
        ad: json['ad'] as String? ?? '',
        ciro: (json['ciro'] as num?)?.toDouble() ?? 0.0,
        adet: (json['adet'] as num?)?.toInt() ?? 0,
      );
}

class MusteriCiro {
  final int cariId;
  final String kod;
  final String ad;
  final double ciro;
  final int adet;

  MusteriCiro({
    required this.cariId,
    required this.kod,
    required this.ad,
    required this.ciro,
    required this.adet,
  });

  factory MusteriCiro.fromJson(Map<String, dynamic> json) => MusteriCiro(
        cariId: (json['cariId'] as num?)?.toInt() ?? 0,
        kod: json['kod'] as String? ?? '',
        ad: json['ad'] as String? ?? '',
        ciro: (json['ciro'] as num?)?.toDouble() ?? 0.0,
        adet: (json['adet'] as num?)?.toInt() ?? 0,
      );
}

// ─── Tahsilat raporu (dbo.CollectionDrafts bazlı) ───────────────────────────
class TahsilatRaporu {
  final double toplamTahsilat; // nakit + kart (giriş)
  final double toplamOdeme; // ödemeler (çıkış)
  final double netTahsilat;
  final double nakitToplam;
  final double kartToplam;
  final int fisSayisi;
  final int bekleyenSayi;
  final int onayliSayi;
  final List<TahsilatSatisci> satiscilar;
  final List<GunlukTahsilat> gunlukTrend;

  TahsilatRaporu({
    required this.toplamTahsilat,
    required this.toplamOdeme,
    required this.netTahsilat,
    required this.nakitToplam,
    required this.kartToplam,
    required this.fisSayisi,
    required this.bekleyenSayi,
    required this.onayliSayi,
    required this.satiscilar,
    required this.gunlukTrend,
  });

  bool get bos => fisSayisi == 0;

  factory TahsilatRaporu.fromJson(Map<String, dynamic> json) => TahsilatRaporu(
        toplamTahsilat: (json['toplamTahsilat'] as num?)?.toDouble() ?? 0.0,
        toplamOdeme: (json['toplamOdeme'] as num?)?.toDouble() ?? 0.0,
        netTahsilat: (json['netTahsilat'] as num?)?.toDouble() ?? 0.0,
        nakitToplam: (json['nakitToplam'] as num?)?.toDouble() ?? 0.0,
        kartToplam: (json['kartToplam'] as num?)?.toDouble() ?? 0.0,
        fisSayisi: (json['fisSayisi'] as num?)?.toInt() ?? 0,
        bekleyenSayi: (json['bekleyenSayi'] as num?)?.toInt() ?? 0,
        onayliSayi: (json['onayliSayi'] as num?)?.toInt() ?? 0,
        satiscilar: (json['satiscilar'] as List<dynamic>? ?? [])
            .map((j) => TahsilatSatisci.fromJson(j as Map<String, dynamic>))
            .toList(),
        gunlukTrend: (json['gunlukTrend'] as List<dynamic>? ?? [])
            .map((j) => GunlukTahsilat.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
}

class TahsilatSatisci {
  final String kullanici;
  final double toplam;
  final int adet;

  TahsilatSatisci({
    required this.kullanici,
    required this.toplam,
    required this.adet,
  });

  factory TahsilatSatisci.fromJson(Map<String, dynamic> json) => TahsilatSatisci(
        kullanici: json['kullanici'] as String? ?? '',
        toplam: (json['toplam'] as num?)?.toDouble() ?? 0.0,
        adet: (json['adet'] as num?)?.toInt() ?? 0,
      );
}

class GunlukTahsilat {
  final DateTime tarih;
  final double toplam;
  final int adet;

  GunlukTahsilat({
    required this.tarih,
    required this.toplam,
    required this.adet,
  });

  factory GunlukTahsilat.fromJson(Map<String, dynamic> json) => GunlukTahsilat(
        tarih: DateTime.parse(json['tarih'] as String),
        toplam: (json['toplam'] as num?)?.toDouble() ?? 0.0,
        adet: (json['adet'] as num?)?.toInt() ?? 0,
      );
}
