class DashboardOzet {
  final double toplamAlacak;
  final double vadesiGecen;
  final double bugunTahsilat;
  final int vadesiGecenCariSayisi;

  /// Gerçek trend — geçen aya göre net değişim yüzdesi.
  /// null = veri yok / hesaplanamadı → UI rozeti gizler (sahte yüzde göstermez).
  final double? trendYuzde;

  DashboardOzet({
    required this.toplamAlacak,
    required this.vadesiGecen,
    required this.bugunTahsilat,
    required this.vadesiGecenCariSayisi,
    this.trendYuzde,
  });

  factory DashboardOzet.fromJson(Map<String, dynamic> json) {
    return DashboardOzet(
      toplamAlacak: (json['toplamAlacak'] as num?)?.toDouble() ?? 0.0,
      vadesiGecen: (json['vadesiGecen'] as num?)?.toDouble() ?? 0.0,
      bugunTahsilat: (json['bugunTahsilat'] as num?)?.toDouble() ?? 0.0,
      vadesiGecenCariSayisi: (json['vadesiGecenCariSayisi'] as int?) ?? 0,
      trendYuzde: (json['trendYuzde'] as num?)?.toDouble(),
    );
  }

  factory DashboardOzet.empty() => DashboardOzet(
    toplamAlacak: 0,
    vadesiGecen: 0,
    bugunTahsilat: 0,
    vadesiGecenCariSayisi: 0,
    trendYuzde: null,
  );
}

class SonHareket {
  final int id;
  final int cariId;
  final String cariCode;
  final String cariTitle;
  final DateTime date;
  final int transactionType;
  final String transactionTypeName;
  final double debit;
  final double credit;

  SonHareket({
    required this.id,
    required this.cariId,
    required this.cariCode,
    required this.cariTitle,
    required this.date,
    required this.transactionType,
    required this.transactionTypeName,
    required this.debit,
    required this.credit,
  });

  /// Bu hareket bir tahsilat mı (para girdi)?
  bool get isTahsilat => credit > 0;

  /// Net tutar — bizim için (+) gelir / (-) gider
  double get netAmount => credit - debit;

  factory SonHareket.fromJson(Map<String, dynamic> json) {
    return SonHareket(
      id: json['id'] as int,
      cariId: json['cariId'] as int,
      cariCode: json['cariCode'] as String? ?? '',
      cariTitle: json['cariTitle'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      transactionType: json['transactionType'] as int,
      transactionTypeName: json['transactionTypeName'] as String? ?? '',
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}