class CariVadeAnalizi {
  final int cariId;
  final double vadesiGelmemis;
  final double vadesi_0_30;
  final double vadesi_31_60;
  final double vadesi_61_90;
  final double vadesi_90Plus;
  final int? enEskiVadeGunFarki;
  final DateTime? enEskiVadeTarihi;
  final DateTime? sonTahsilatTarihi;

  CariVadeAnalizi({
    required this.cariId,
    required this.vadesiGelmemis,
    required this.vadesi_0_30,
    required this.vadesi_31_60,
    required this.vadesi_61_90,
    required this.vadesi_90Plus,
    this.enEskiVadeGunFarki,
    this.enEskiVadeTarihi,
    this.sonTahsilatTarihi,
  });

  double get toplamVadesiGecen =>
      vadesi_0_30 + vadesi_31_60 + vadesi_61_90 + vadesi_90Plus;

  double get bakiye => vadesiGelmemis + toplamVadesiGecen;

  bool get hasVadesiGecen => toplamVadesiGecen > 0;

  factory CariVadeAnalizi.fromJson(Map<String, dynamic> json) {
    return CariVadeAnalizi(
      cariId: json['cariId'] as int,
      vadesiGelmemis: (json['vadesiGelmemis'] as num?)?.toDouble() ?? 0,
      vadesi_0_30: (json['vadesi_0_30'] as num?)?.toDouble() ?? 0,
      vadesi_31_60: (json['vadesi_31_60'] as num?)?.toDouble() ?? 0,
      vadesi_61_90: (json['vadesi_61_90'] as num?)?.toDouble() ?? 0,
      vadesi_90Plus: (json['vadesi_90Plus'] as num?)?.toDouble() ?? 0,
      enEskiVadeGunFarki: json['enEskiVadeGunFarki'] as int?,
      enEskiVadeTarihi: json['enEskiVadeTarihi'] != null
          ? DateTime.parse(json['enEskiVadeTarihi'] as String)
          : null,
      sonTahsilatTarihi: json['sonTahsilatTarihi'] != null
          ? DateTime.parse(json['sonTahsilatTarihi'] as String)
          : null,
    );
  }
}