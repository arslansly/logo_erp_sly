import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ─── İrsaliye türleri (STFICHE.TRCODE) ─────────────────────────────────────
// Listede sadece satış/satınalma + iadeler gösterilir (1,2,3,6,7,8).
enum IrsaliyeTuru {
  satinalma(1, 'Satınalma İrsaliyesi', 'Satınalma'),
  perakendeSatisIade(2, 'Perakende Satış İade İrsaliyesi', 'İade'),
  toptanSatisIade(3, 'Toptan Satış İade İrsaliyesi', 'İade'),
  satinalmaIade(6, 'Satınalma İade İrsaliyesi', 'İade'),
  perakendeSatis(7, 'Perakende Satış İrsaliyesi', 'Satış'),
  toptanSatis(8, 'Toptan Satış İrsaliyesi', 'Satış');

  final int trCode;
  final String adi;
  final String kategori;
  const IrsaliyeTuru(this.trCode, this.adi, this.kategori);

  static IrsaliyeTuru? fromTrCode(int code) {
    for (final t in IrsaliyeTuru.values) {
      if (t.trCode == code) return t;
    }
    return null;
  }

  IconData get ikon => switch (kategori) {
        'Satış' => Icons.local_shipping_rounded,
        'Satınalma' => Icons.inventory_2_rounded,
        'İade' => Icons.assignment_return_rounded,
        _ => Icons.receipt_long_rounded,
      };

  Color get renk => switch (kategori) {
        'Satış' => AppColors.positive,
        'Satınalma' => AppColors.cyan,
        'İade' => AppColors.warning,
        _ => AppColors.slate500,
      };
}

// ─── Liste / kart modeli ───────────────────────────────────────────────────
class IrsaliyeModel {
  final int id;
  final String ficheNo;
  final String docCode;
  final DateTime date;
  final int trCode;
  final String trCodeName;
  final int clientRef;
  final String clientCode;
  final String clientTitle;
  final double netTotal;
  final int? invoiceRef;
  final String invNo;
  final int billed;
  final int cancelled;
  // Taslak akışı için
  final bool isDraft;
  final String draftStatus; // 'Draft' | 'Transferred' | 'Failed'
  final String? lastError;

  IrsaliyeModel({
    required this.id,
    required this.ficheNo,
    required this.docCode,
    required this.date,
    required this.trCode,
    required this.trCodeName,
    required this.clientRef,
    required this.clientCode,
    required this.clientTitle,
    required this.netTotal,
    this.invoiceRef,
    required this.invNo,
    required this.billed,
    required this.cancelled,
    this.isDraft = false,
    this.draftStatus = '',
    this.lastError,
  });

  factory IrsaliyeModel.fromJson(Map<String, dynamic> json) => IrsaliyeModel(
        id: json['id'] as int,
        ficheNo: json['ficheNo'] as String? ?? '',
        docCode: json['docCode'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        trCode: json['trCode'] as int,
        trCodeName: json['trCodeName'] as String? ?? '',
        clientRef: json['clientRef'] as int? ?? 0,
        clientCode: json['clientCode'] as String? ?? '',
        clientTitle: json['clientTitle'] as String? ?? '',
        netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
        invoiceRef: json['invoiceRef'] as int?,
        invNo: json['invNo'] as String? ?? '',
        billed: json['billed'] as int? ?? 0,
        cancelled: json['cancelled'] as int? ?? 0,
        isDraft: json['isDraft'] as bool? ?? false,
        draftStatus: json['draftStatus'] as String? ?? '',
        lastError: json['lastError'] as String?,
      );

  IrsaliyeTuru? get tur => IrsaliyeTuru.fromTrCode(trCode);
  bool get isFaturalandi => billed != 0;
  bool get isIptal => cancelled != 0;
  bool get isTaslak => isDraft && draftStatus == 'Draft';
  bool get isAktarildi => !isDraft || draftStatus == 'Transferred';
  bool get isHatali => isDraft && draftStatus == 'Failed';
}

// ─── İrsaliye satırı ───────────────────────────────────────────────────────
class IrsaliyeSatirModel {
  final int id;
  final int lineNo;
  final int lineType;
  final String lineTypeName;
  final int? stockRef;
  final String stockCode;
  final String stockName;
  final String uomCode;
  final double amount;
  final double price;
  final double vatRate;
  final double total;
  final double vatAmount;
  final double lineNet;
  final double discount;
  final String lineDescription;

  IrsaliyeSatirModel({
    required this.id,
    required this.lineNo,
    required this.lineType,
    required this.lineTypeName,
    this.stockRef,
    required this.stockCode,
    required this.stockName,
    required this.uomCode,
    required this.amount,
    required this.price,
    required this.vatRate,
    required this.total,
    required this.vatAmount,
    required this.lineNet,
    required this.discount,
    required this.lineDescription,
  });

  factory IrsaliyeSatirModel.fromJson(Map<String, dynamic> json) =>
      IrsaliyeSatirModel(
        id: json['id'] as int? ?? 0,
        lineNo: json['lineNo'] as int? ?? 0,
        lineType: json['lineType'] as int? ?? 0,
        lineTypeName: json['lineTypeName'] as String? ?? '',
        stockRef: json['stockRef'] as int?,
        stockCode: json['stockCode'] as String? ?? '',
        stockName: json['stockName'] as String? ?? '',
        uomCode: json['uomCode'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0,
        lineNet: (json['lineNet'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        lineDescription: json['lineDescription'] as String? ?? '',
      );
}

// ─── Detay bundle ──────────────────────────────────────────────────────────
class IrsaliyeDetayModel {
  final IrsaliyeModel baslik;
  final List<IrsaliyeSatirModel> satirlar;
  final String genExp1;
  final String genExp2;

  IrsaliyeDetayModel({
    required this.baslik,
    required this.satirlar,
    this.genExp1 = '',
    this.genExp2 = '',
  });

  factory IrsaliyeDetayModel.fromJson(Map<String, dynamic> json) =>
      IrsaliyeDetayModel(
        baslik: IrsaliyeModel.fromJson(json['baslik'] as Map<String, dynamic>),
        satirlar: (json['satirlar'] as List<dynamic>)
            .map((j) => IrsaliyeSatirModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        genExp1: json['genExp1'] as String? ?? '',
        genExp2: json['genExp2'] as String? ?? '',
      );

  Iterable<String> get aciklamalar =>
      [genExp1, genExp2].where((s) => s.isNotEmpty);
}

// ─── Taslak modelleri (form için mutable) ──────────────────────────────────
// Fatura taslağıyla paralel; ek olarak ambar (sourceIndex/destIndex) ve
// taşıyıcı kodu (shipInfoCode) içerir. Satış/satınalma elemanı yok.
class IrsaliyeTaslakModel {
  int? id;
  int trCode;
  String? ficheNo;
  String? docCode;
  DateTime date;
  int clientRef;
  String clientCode;
  String clientTitle;
  int? sourceIndex; // kaynak ambar (L_CAPIWHOUSE.NR)
  int? destIndex; // hedef ambar
  String? shipInfoCode; // taşıyıcı kodu (serbest metin)
  double grossTotal;
  double totalDiscounts;
  double totalVat;
  double netTotal;
  int currencyType; // 0=TL, >0=L_CURRENCYLIST.CURTYPE
  double exchangeRate; // TL ise 1.0
  String? genExp1;
  String? genExp2;
  String status;
  int? transferredShipmentId;
  DateTime? transferredAt;
  String? lastError;
  String createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<IrsaliyeTaslakSatirModel> lines;

  IrsaliyeTaslakModel({
    this.id,
    required this.trCode,
    this.ficheNo,
    this.docCode,
    required this.date,
    required this.clientRef,
    required this.clientCode,
    required this.clientTitle,
    this.sourceIndex,
    this.destIndex,
    this.shipInfoCode,
    this.grossTotal = 0,
    this.totalDiscounts = 0,
    this.totalVat = 0,
    this.netTotal = 0,
    this.currencyType = 0,
    this.exchangeRate = 1.0,
    this.genExp1,
    this.genExp2,
    this.status = 'Draft',
    this.transferredShipmentId,
    this.transferredAt,
    this.lastError,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
    List<IrsaliyeTaslakSatirModel>? lines,
  }) : lines = lines ?? [];

  factory IrsaliyeTaslakModel.fromJson(Map<String, dynamic> json) =>
      IrsaliyeTaslakModel(
        id: json['id'] as int?,
        trCode: json['trCode'] as int,
        ficheNo: json['ficheNo'] as String?,
        docCode: json['docCode'] as String?,
        date: DateTime.parse(json['date'] as String),
        clientRef: json['clientRef'] as int,
        clientCode: json['clientCode'] as String? ?? '',
        clientTitle: json['clientTitle'] as String? ?? '',
        sourceIndex: json['sourceIndex'] as int?,
        destIndex: json['destIndex'] as int?,
        shipInfoCode: json['shipInfoCode'] as String?,
        grossTotal: (json['grossTotal'] as num?)?.toDouble() ?? 0,
        totalDiscounts: (json['totalDiscounts'] as num?)?.toDouble() ?? 0,
        totalVat: (json['totalVat'] as num?)?.toDouble() ?? 0,
        netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
        currencyType: json['currencyType'] as int? ?? 0,
        exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 1.0,
        genExp1: json['genExp1'] as String?,
        genExp2: json['genExp2'] as String?,
        status: json['status'] as String? ?? 'Draft',
        transferredShipmentId: json['transferredShipmentId'] as int?,
        transferredAt: (json['transferredAt'] as String?) != null
            ? DateTime.parse(json['transferredAt'] as String)
            : null,
        lastError: json['lastError'] as String?,
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: (json['createdAt'] as String?) != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: (json['updatedAt'] as String?) != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        lines: (json['lines'] as List<dynamic>? ?? [])
            .map((j) =>
                IrsaliyeTaslakSatirModel.fromJson(j as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'trCode': trCode,
        'ficheNo': ficheNo,
        'docCode': docCode,
        'date': date.toIso8601String(),
        'clientRef': clientRef,
        'clientCode': clientCode,
        'clientTitle': clientTitle,
        'sourceIndex': sourceIndex,
        'destIndex': destIndex,
        'shipInfoCode': shipInfoCode,
        'grossTotal': grossTotal,
        'totalDiscounts': totalDiscounts,
        'totalVat': totalVat,
        'netTotal': netTotal,
        'currencyType': currencyType,
        'exchangeRate': exchangeRate,
        'genExp1': genExp1,
        'genExp2': genExp2,
        'status': status,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  void recomputeTotals() {
    grossTotal = 0;
    totalDiscounts = 0;
    totalVat = 0;
    for (final l in lines) {
      l.recomputeTotals();
      grossTotal += l.total;
      totalDiscounts += l.discount;
      totalVat += l.vatAmount;
    }
    netTotal = grossTotal - totalDiscounts + totalVat;
  }
}

class IrsaliyeTaslakSatirModel {
  int? id;
  int? draftId;
  int lineNo;
  int lineType;
  int? stockRef;
  String? stockCode;
  String? stockName;
  int? uomRef;
  String? uomCode;
  double amount;
  double price;
  double vatRate;
  double discount;
  double total;
  double vatAmount;
  double lineNet;
  String? lineDescription;

  IrsaliyeTaslakSatirModel({
    this.id,
    this.draftId,
    this.lineNo = 0,
    this.lineType = 0,
    this.stockRef,
    this.stockCode,
    this.stockName,
    this.uomRef,
    this.uomCode,
    this.amount = 0,
    this.price = 0,
    this.vatRate = 0,
    this.discount = 0,
    this.total = 0,
    this.vatAmount = 0,
    this.lineNet = 0,
    this.lineDescription,
  });

  factory IrsaliyeTaslakSatirModel.fromJson(Map<String, dynamic> json) =>
      IrsaliyeTaslakSatirModel(
        id: json['id'] as int?,
        draftId: json['draftId'] as int?,
        lineNo: json['lineNo'] as int? ?? 0,
        lineType: json['lineType'] as int? ?? 0,
        stockRef: json['stockRef'] as int?,
        stockCode: json['stockCode'] as String?,
        stockName: json['stockName'] as String?,
        uomRef: json['uomRef'] as int?,
        uomCode: json['uomCode'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0,
        lineNet: (json['lineNet'] as num?)?.toDouble() ?? 0,
        lineDescription: json['lineDescription'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (draftId != null) 'draftId': draftId,
        'lineNo': lineNo,
        'lineType': lineType,
        'stockRef': stockRef,
        'stockCode': stockCode,
        'stockName': stockName,
        'uomRef': uomRef,
        'uomCode': uomCode,
        'amount': amount,
        'price': price,
        'vatRate': vatRate,
        'discount': discount,
        'total': total,
        'vatAmount': vatAmount,
        'lineNet': lineNet,
        'lineDescription': lineDescription,
      };

  void recomputeTotals() {
    total = amount * price;
    final tabani = total - discount;
    vatAmount = tabani * vatRate / 100;
    lineNet = tabani + vatAmount;
  }
}
