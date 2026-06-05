class VadesiGecenCari {
  final int id;
  final String code;
  final String title;
  final String city;
  final String phone;
  final double vadesiGecenTutar;
  final int enEskiGunFarki;
  final DateTime enEskiVadeTarihi;
  final int vadeSayisi;

  VadesiGecenCari({
    required this.id,
    required this.code,
    required this.title,
    required this.city,
    required this.phone,
    required this.vadesiGecenTutar,
    required this.enEskiGunFarki,
    required this.enEskiVadeTarihi,
    required this.vadeSayisi,
  });

  /// Risk seviyesi: kritik (90+), yüksek (60+), orta (30+), düşük (0-30)
  RiskLevel get riskLevel {
    if (enEskiGunFarki >= 90) return RiskLevel.kritik;
    if (enEskiGunFarki >= 60) return RiskLevel.yuksek;
    if (enEskiGunFarki >= 30) return RiskLevel.orta;
    return RiskLevel.dusuk;
  }

  factory VadesiGecenCari.fromJson(Map<String, dynamic> json) {
    return VadesiGecenCari(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      vadesiGecenTutar: (json['vadesiGecenTutar'] as num?)?.toDouble() ?? 0,
      enEskiGunFarki: json['enEskiGunFarki'] as int? ?? 0,
      enEskiVadeTarihi: DateTime.parse(json['enEskiVadeTarihi'] as String),
      vadeSayisi: json['vadeSayisi'] as int? ?? 0,
    );
  }
}

enum RiskLevel { dusuk, orta, yuksek, kritik }