// Saha (satışçı) paneli veri modelleri — backend `SahaSatisci`/`SahaOzet`/
// `SahaAcikSiparis`/`SahaRiskliCari` ile JSON sözleşmesini paylaşır (camelCase).

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

/// Satışçı + açık iş özeti (leaderboard ve seçici kaynağı).
class SahaSatisci {
  final int id;
  final String kod;
  final String ad;
  final int acikSiparisAdet;
  final double acikSiparisTutar;
  final int musteriSayisi;

  const SahaSatisci({
    required this.id,
    required this.kod,
    required this.ad,
    required this.acikSiparisAdet,
    required this.acikSiparisTutar,
    required this.musteriSayisi,
  });

  factory SahaSatisci.fromJson(Map<String, dynamic> j) => SahaSatisci(
        id: _i(j['id']),
        kod: j['kod'] as String? ?? '',
        ad: j['ad'] as String? ?? '',
        acikSiparisAdet: _i(j['acikSiparisAdet']),
        acikSiparisTutar: _d(j['acikSiparisTutar']),
        musteriSayisi: _i(j['musteriSayisi']),
      );
}

/// Seçili kapsam (satışçı / tümü) özeti.
class SahaOzet {
  final int? satisciRef;
  final String satisciAd;
  final double acikSiparisTutar;
  final int acikSiparisAdet;
  final int musteriSayisi;
  final int riskliCariSayisi;
  final double vadesiGecenToplam;
  final int limitAsanSayisi; // kredi limitini aşan müşteri (0 = firma limit kullanmıyor)

  const SahaOzet({
    required this.satisciRef,
    required this.satisciAd,
    required this.acikSiparisTutar,
    required this.acikSiparisAdet,
    required this.musteriSayisi,
    required this.riskliCariSayisi,
    required this.vadesiGecenToplam,
    required this.limitAsanSayisi,
  });

  factory SahaOzet.fromJson(Map<String, dynamic> j) => SahaOzet(
        satisciRef: j['satisciRef'] as int?,
        satisciAd: j['satisciAd'] as String? ?? 'Tüm satışçılar',
        acikSiparisTutar: _d(j['acikSiparisTutar']),
        acikSiparisAdet: _i(j['acikSiparisAdet']),
        musteriSayisi: _i(j['musteriSayisi']),
        riskliCariSayisi: _i(j['riskliCariSayisi']),
        vadesiGecenToplam: _d(j['vadesiGecenToplam']),
        limitAsanSayisi: _i(j['limitAsanSayisi']),
      );
}

/// Açık (sevk bekleyen) sipariş satırı.
class SahaAcikSiparis {
  final int id;
  final String ficheNo;
  final DateTime tarih;
  final int cariId;
  final String cariAd;
  final String satisciAd;
  final double bekleyenTutar;
  final int gunGecti;

  const SahaAcikSiparis({
    required this.id,
    required this.ficheNo,
    required this.tarih,
    required this.cariId,
    required this.cariAd,
    required this.satisciAd,
    required this.bekleyenTutar,
    required this.gunGecti,
  });

  factory SahaAcikSiparis.fromJson(Map<String, dynamic> j) => SahaAcikSiparis(
        id: _i(j['id']),
        ficheNo: j['ficheNo'] as String? ?? '',
        tarih: DateTime.tryParse(j['tarih'] as String? ?? '') ?? DateTime.now(),
        cariId: _i(j['cariId']),
        cariAd: j['cariAd'] as String? ?? '',
        satisciAd: j['satisciAd'] as String? ?? '',
        bekleyenTutar: _d(j['bekleyenTutar']),
        gunGecti: _i(j['gunGecti']),
      );

  /// 30 günden fazla bekleyen sipariş "bayatlamış" sayılır (saha takibi için).
  bool get bayat => gunGecti > 30;
}

/// Riskli müşteri — vadesi geçen alacağı olan cari.
class SahaRiskliCari {
  final int cariId;
  final String cariKod;
  final String cariAd;
  final double bakiye;
  final double vadesiGecen;
  final int enEskiGun;
  final double acikSiparis;
  final double krediLimiti; // 0 = limit tanımsız

  const SahaRiskliCari({
    required this.cariId,
    required this.cariKod,
    required this.cariAd,
    required this.bakiye,
    required this.vadesiGecen,
    required this.enEskiGun,
    required this.acikSiparis,
    required this.krediLimiti,
  });

  /// Toplam risk = ödenecek bakiye (borç) + sevk bekleyen sipariş.
  double get toplamRisk => (bakiye > 0 ? bakiye : 0) + acikSiparis;

  /// Kredi limiti aşıldı mı (limit tanımlıysa).
  bool get limitAsildi => krediLimiti > 0 && toplamRisk > krediLimiti;

  factory SahaRiskliCari.fromJson(Map<String, dynamic> j) => SahaRiskliCari(
        cariId: _i(j['cariId']),
        cariKod: j['cariKod'] as String? ?? '',
        cariAd: j['cariAd'] as String? ?? '',
        bakiye: _d(j['bakiye']),
        vadesiGecen: _d(j['vadesiGecen']),
        enEskiGun: _i(j['enEskiGun']),
        acikSiparis: _d(j['acikSiparis']),
        krediLimiti: _d(j['krediLimiti']),
      );
}
