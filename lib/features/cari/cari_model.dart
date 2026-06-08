class Cari {
  final int id;
  final String code;
  final String title;
  final double balance;
  final String city;
  final String phone;
  final String taxNumber;
  final String address;
  final String email;
  final String country;
  // CLCARD.EINVOICE → 0: yok, 1: e-Fatura, 2: e-Arşiv
  final int eInvoiceType;
  // Açık (sevk bekleyen) satış siparişi tutarı — yalnızca detay (getById) çağrısında dolu.
  final double acikSiparis;
  // Kredi/risk limiti (CLCARD.DBSLIMIT en yükseği). 0 = firma limit kullanmıyor → "tanımsız".
  final double krediLimiti;
  // Firma bu cari için risk kontrolü açmış mı.
  final bool riskKontrolVar;

  Cari({
    required this.id,
    required this.code,
    required this.title,
    required this.balance,
    required this.city,
    required this.phone,
    this.taxNumber = '',
    this.address = '',
    this.email = '',
    this.country = '',
    this.eInvoiceType = 0,
    this.acikSiparis = 0.0,
    this.krediLimiti = 0.0,
    this.riskKontrolVar = false,
  });

  factory Cari.fromJson(Map<String, dynamic> json) {
    return Cari(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      taxNumber: json['taxNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      country: json['country'] as String? ?? '',
      eInvoiceType: json['eInvoiceType'] as int? ?? 0,
      acikSiparis: (json['acikSiparis'] as num?)?.toDouble() ?? 0.0,
      krediLimiti: (json['krediLimiti'] as num?)?.toDouble() ?? 0.0,
      riskKontrolVar: json['riskKontrolVar'] as bool? ?? false,
    );
  }

  bool get isBorclu => balance > 0;
  bool get isAlacakli => balance < 0;
  bool get isSifir => balance == 0;

  /// Toplam risk = ödenecek bakiye (müşteri borçluysa) + sevk bekleyen sipariş.
  double get toplamRisk => (balance > 0 ? balance : 0) + acikSiparis;

  /// Firma bu cari için kredi limiti tanımlamış mı (limit kullanmayan firmada false).
  bool get limitTanimli => krediLimiti > 0;

  /// Kalan limit = limit − toplam risk (negatif = aşım). Limit yoksa 0.
  double get kalanLimit => limitTanimli ? krediLimiti - toplamRisk : 0;

  /// Limit aşıldı mı.
  bool get limitAsildi => limitTanimli && toplamRisk > krediLimiti;

  /// Limit kullanım oranı (0–1, bar için clamp'li). Limit yoksa 0.
  double get limitKullanimOrani =>
      limitTanimli ? (toplamRisk / krediLimiti).clamp(0.0, 1.0) : 0.0;

  /// Limit kullanım yüzdesi (aşımda 100'ü geçebilir).
  double get limitKullanimYuzde =>
      limitTanimli ? (toplamRisk / krediLimiti) * 100 : 0;

  bool get eFatura => eInvoiceType == 1;
  bool get eArsiv => eInvoiceType == 2;
}