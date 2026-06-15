import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Saha gider (masraf) kategorileri — backend OnayService.MasrafKategoriAdi ve
// ExpenseDrafts.Category ile birebir aynı anahtarlar.
enum MasrafKategori {
  benzin('benzin', 'Benzin', Icons.local_gas_station_rounded),
  otopark('otopark', 'Otopark', Icons.local_parking_rounded),
  yemek('yemek', 'Yemek', Icons.restaurant_rounded),
  konaklama('konaklama', 'Konaklama', Icons.hotel_rounded),
  kopru('kopru', 'Köprü/Otoyol', Icons.alt_route_rounded),
  diger('diger', 'Diğer', Icons.receipt_long_rounded);

  const MasrafKategori(this.api, this.adi, this.ikon);

  final String api;
  final String adi;
  final IconData ikon;

  Color get renk => switch (this) {
        MasrafKategori.benzin => AppColors.warning,
        MasrafKategori.otopark => AppColors.accent,
        MasrafKategori.yemek => AppColors.positive,
        MasrafKategori.konaklama => AppColors.primary,
        MasrafKategori.kopru => AppColors.negative,
        MasrafKategori.diger => AppColors.slate500,
      };

  static MasrafKategori fromApi(String? v) =>
      values.firstWhere((k) => k.api == v, orElse: () => MasrafKategori.diger);
}

// Saha gider fişi — backend (/api/ExpenseDraft) ile alışveriş modeli.
// Tek para hareketi + fiş fotoğrafı taşır. Fotoğraf ayrı endpoint'ten yüklenir
// (multipart) ve gösterilir (/api/ExpenseDraft/{id}/receipt).
class MasrafModel {
  int? id;
  String category; // MasrafKategori.api
  String? docCode;
  DateTime date;
  double amount;
  int currencyType; // 0=TL
  double exchangeRate;
  String? aciklama;
  bool hasReceipt; // sunucuda fiş fotoğrafı var mı

  String? approvalStatus; // 'Pending' | 'Approved' | 'Rejected'
  String? approvedBy;
  DateTime? approvedAt;
  String? rejectReason;

  String paymentStatus; // 'Unpaid' | 'Paid'
  String? paidBy;
  DateTime? paidAt;
  String? paymentMethod;

  String createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;

  MasrafModel({
    this.id,
    required this.category,
    this.docCode,
    required this.date,
    this.amount = 0,
    this.currencyType = 0,
    this.exchangeRate = 1.0,
    this.aciklama,
    this.hasReceipt = false,
    this.approvalStatus,
    this.approvedBy,
    this.approvedAt,
    this.rejectReason,
    this.paymentStatus = 'Unpaid',
    this.paidBy,
    this.paidAt,
    this.paymentMethod,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  MasrafKategori get kategori => MasrafKategori.fromApi(category);

  bool get isOnaylandi => approvalStatus == 'Approved';
  bool get isReddedildi => approvalStatus == 'Rejected';
  bool get isOnayBekliyor => approvalStatus == 'Pending';
  bool get isOdendi => paymentStatus == 'Paid';

  factory MasrafModel.fromJson(Map<String, dynamic> json) => MasrafModel(
        id: json['id'] as int?,
        category: json['category'] as String? ?? 'diger',
        docCode: json['docCode'] as String?,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currencyType: json['currencyType'] as int? ?? 0,
        exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 1.0,
        aciklama: json['aciklama'] as String?,
        hasReceipt: json['hasReceipt'] as bool? ?? false,
        approvalStatus: json['approvalStatus'] as String?,
        approvedBy: json['approvedBy'] as String?,
        approvedAt: (json['approvedAt'] as String?) != null
            ? DateTime.tryParse(json['approvedAt'] as String)
            : null,
        rejectReason: json['rejectReason'] as String?,
        paymentStatus: json['paymentStatus'] as String? ?? 'Unpaid',
        paidBy: json['paidBy'] as String?,
        paidAt: (json['paidAt'] as String?) != null
            ? DateTime.tryParse(json['paidAt'] as String)
            : null,
        paymentMethod: json['paymentMethod'] as String?,
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: (json['createdAt'] as String?) != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: (json['updatedAt'] as String?) != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  // Multipart form alanları — sayısal değerler '.' ondalıkla (invariant) gider,
  // backend InvariantCulture ile parse eder.
  Map<String, String> toFormFields() => {
        'category': category,
        'amount': amount.toString(),
        'date': date.toIso8601String(),
        'currencyType': currencyType.toString(),
        'exchangeRate': exchangeRate.toString(),
        if (docCode != null && docCode!.isNotEmpty) 'docCode': docCode!,
        if (aciklama != null && aciklama!.isNotEmpty) 'aciklama': aciklama!,
      };
}
