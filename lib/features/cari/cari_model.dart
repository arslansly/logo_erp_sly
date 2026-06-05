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
    );
  }

  bool get isBorclu => balance > 0;
  bool get isAlacakli => balance < 0;
  bool get isSifir => balance == 0;

  bool get eFatura => eInvoiceType == 1;
  bool get eArsiv => eInvoiceType == 2;
}