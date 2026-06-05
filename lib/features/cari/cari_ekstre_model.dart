class CariEkstreSatir {
  final int id;
  final DateTime tarih;
  final int islemTipi;
  final String islemTipiAdi;
  final String documentNo;
  final String aciklama;
  final double borc;
  final double alacak;
  final double yurutulenBakiye;

  CariEkstreSatir({
    required this.id,
    required this.tarih,
    required this.islemTipi,
    required this.islemTipiAdi,
    required this.documentNo,
    required this.aciklama,
    required this.borc,
    required this.alacak,
    required this.yurutulenBakiye,
  });

  factory CariEkstreSatir.fromJson(Map<String, dynamic> json) {
    return CariEkstreSatir(
      id: json['id'] as int,
      tarih: DateTime.parse(json['tarih'] as String),
      islemTipi: json['islemTipi'] as int,
      islemTipiAdi: json['islemTipiAdi'] as String? ?? '',
      documentNo: json['documentNo'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      borc: (json['borc'] as num?)?.toDouble() ?? 0.0,
      alacak: (json['alacak'] as num?)?.toDouble() ?? 0.0,
      yurutulenBakiye: (json['yurutulenBakiye'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CariEkstre {
  final int cariId;
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final double devirBakiyesi;
  final double toplamBorc;
  final double toplamAlacak;
  final double kapanisBakiyesi;
  final List<CariEkstreSatir> hareketler;

  CariEkstre({
    required this.cariId,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.devirBakiyesi,
    required this.toplamBorc,
    required this.toplamAlacak,
    required this.kapanisBakiyesi,
    required this.hareketler,
  });

  double get netHareket => toplamBorc - toplamAlacak;

  factory CariEkstre.fromJson(Map<String, dynamic> json) {
    return CariEkstre(
      cariId: json['cariId'] as int,
      baslangicTarihi: DateTime.parse(json['baslangicTarihi'] as String),
      bitisTarihi: DateTime.parse(json['bitisTarihi'] as String),
      devirBakiyesi: (json['devirBakiyesi'] as num?)?.toDouble() ?? 0.0,
      toplamBorc: (json['toplamBorc'] as num?)?.toDouble() ?? 0.0,
      toplamAlacak: (json['toplamAlacak'] as num?)?.toDouble() ?? 0.0,
      kapanisBakiyesi: (json['kapanisBakiyesi'] as num?)?.toDouble() ?? 0.0,
      hareketler: (json['hareketler'] as List<dynamic>? ?? [])
          .map((e) => CariEkstreSatir.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
