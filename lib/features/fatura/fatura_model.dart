import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ─── Fatura türleri (LOGO INVOICE.TRCODE karşılığı) ────────────────────────
enum FaturaTuru {
  satinalma(31, 'Satınalma Faturası', 'Satınalma'),
  perakendeSatisIade(32, 'Perakende Satış İade Faturası', 'İade'),
  toptanSatisIade(33, 'Toptan Satış İade Faturası', 'İade'),
  alinanHizmet(34, 'Alınan Hizmet Faturası', 'Satınalma'),
  satinalmaIade(36, 'Satınalma İade Faturası', 'İade'),
  perakendeSatis(37, 'Perakende Satış Faturası', 'Satış'),
  toptanSatis(38, 'Toptan Satış Faturası', 'Satış'),
  verilenHizmet(39, 'Verilen Hizmet Faturası', 'Satış'),
  verilenVadeFarki(41, 'Verilen Vade Farkı Faturası', 'Satış'),
  alinanVadeFarki(42, 'Alınan Vade Farkı Faturası', 'Satınalma'),
  satinalmaFiyatFarki(43, 'Satınalma Fiyat Farkı Faturası', 'Satınalma'),
  satisFiyatFarki(44, 'Satış Fiyat Farkı Faturası', 'Satış'),
  mustahsil(56, 'Müstahsil Makbuzu', 'Satınalma');

  final int trCode;
  final String adi;
  final String kategori; // "Satış" | "Satınalma" | "İade"
  const FaturaTuru(this.trCode, this.adi, this.kategori);

  static FaturaTuru? fromTrCode(int code) {
    for (final t in FaturaTuru.values) {
      if (t.trCode == code) return t;
    }
    return null;
  }

  IconData get ikon {
    switch (kategori) {
      case 'Satış':     return Icons.trending_up_rounded;
      case 'Satınalma': return Icons.trending_down_rounded;
      case 'İade':      return Icons.undo_rounded;
      default:          return Icons.receipt_rounded;
    }
  }

  Color get renk {
    switch (kategori) {
      case 'Satış':     return AppColors.positive;
      case 'Satınalma': return AppColors.cyan;
      case 'İade':      return AppColors.warning;
      default:          return AppColors.slate500;
    }
  }
}

// ─── Liste / kart modeli (hem LOGO faturası hem taslak) ───────────────────
class FaturaModel {
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
  final double grossTotal;
  final double totalVat;
  final double totalDiscounts;
  final int cancelled;
  // Taslak akışı için
  final bool isDraft;
  final String draftStatus; // 'Draft' | 'Transferred' | 'Failed'
  final String? lastError;
  final String? approvalStatus; // 'Pending' | 'Approved' | 'Rejected'

  FaturaModel({
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
    required this.grossTotal,
    required this.totalVat,
    required this.totalDiscounts,
    required this.cancelled,
    this.isDraft = false,
    this.draftStatus = '',
    this.lastError,
    this.approvalStatus,
  });

  factory FaturaModel.fromJson(Map<String, dynamic> json) => FaturaModel(
        id: json['id'] as int,
        ficheNo: json['ficheNo'] as String? ?? '',
        docCode: json['docCode'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        trCode: json['trCode'] as int,
        trCodeName: json['trCodeName'] as String? ?? '',
        clientRef: json['clientRef'] as int? ?? 0,
        clientCode: json['clientCode'] as String? ?? '',
        clientTitle: json['clientTitle'] as String? ?? '',
        netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0.0,
        grossTotal: (json['grossTotal'] as num?)?.toDouble() ?? 0.0,
        totalVat: (json['totalVat'] as num?)?.toDouble() ?? 0.0,
        totalDiscounts: (json['totalDiscounts'] as num?)?.toDouble() ?? 0.0,
        cancelled: json['cancelled'] as int? ?? 0,
        isDraft: json['isDraft'] as bool? ?? false,
        draftStatus: json['draftStatus'] as String? ?? '',
        lastError: json['lastError'] as String?,
        approvalStatus: json['approvalStatus'] as String?,
      );

  FaturaTuru? get tur => FaturaTuru.fromTrCode(trCode);
  bool get isTaslak => isDraft && draftStatus == 'Draft';
  // Onay durumu — yalnızca taslakta anlamlı
  bool get isOnayBekliyor => isDraft && approvalStatus == 'Pending';
  bool get isOnaylandi => isDraft && approvalStatus == 'Approved';
  bool get isReddedildi => isDraft && approvalStatus == 'Rejected';
  bool get isAktarildi => !isDraft || draftStatus == 'Transferred';
  bool get isHatali => isDraft && draftStatus == 'Failed';
  bool get isIptal => cancelled != 0;

  // LOGO faturaları INVOICE.TRCODE'u 1-9 (STFICHE benzeri) kullanır; taslaklar
  // 31-56 (FaturaTuru). Bu yüzden gösterim için trCodeName + kod tabanlı kategori.
  String get _kategori {
    if (tur != null) return tur!.kategori;
    switch (trCode) {
      case 7:
      case 8:
      case 9:
        return 'Satış';
      case 1:
      case 4:
        return 'Satınalma';
      case 2:
      case 3:
      case 6:
        return 'İade';
      default:
        return '';
    }
  }

  String get displayAd =>
      trCodeName.isNotEmpty ? trCodeName : (tur?.adi ?? 'Tip $trCode');

  Color get displayRenk {
    switch (_kategori) {
      case 'Satış':
        return AppColors.positive;
      case 'Satınalma':
        return AppColors.cyan;
      case 'İade':
        return AppColors.warning;
      default:
        return AppColors.slate500;
    }
  }

  IconData get displayIkon {
    switch (_kategori) {
      case 'Satış':
        return Icons.trending_up_rounded;
      case 'Satınalma':
        return Icons.trending_down_rounded;
      case 'İade':
        return Icons.undo_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }
}

// ─── Fatura satır modeli ───────────────────────────────────────────────────
class FaturaSatirModel {
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

  FaturaSatirModel({
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

  factory FaturaSatirModel.fromJson(Map<String, dynamic> json) =>
      FaturaSatirModel(
        id: json['id'] as int? ?? 0,
        lineNo: json['lineNo'] as int? ?? 0,
        lineType: json['lineType'] as int? ?? 0,
        lineTypeName: json['lineTypeName'] as String? ?? '',
        stockRef: json['stockRef'] as int?,
        stockCode: json['stockCode'] as String? ?? '',
        stockName: json['stockName'] as String? ?? '',
        uomCode: json['uomCode'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0.0,
        lineNet: (json['lineNet'] as num?)?.toDouble() ?? 0.0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        lineDescription: json['lineDescription'] as String? ?? '',
      );

  // LINETYPE → renk: malzeme=accent, hizmet=primary, masraf=warning, iskonto=negative
  Color get lineTypeColor {
    switch (lineType) {
      case 0: return AppColors.accent;
      case 1: return AppColors.primary;
      case 2: return AppColors.warning;
      case 4: return AppColors.negative;
      default: return AppColors.slate500;
    }
  }
}

// ─── Bağlı belge (irsaliye/sipariş) ────────────────────────────────────────
class BagliBelgeModel {
  final int id;
  final String ficheNo;
  final DateTime date;
  final int trCode;
  final String trCodeName;
  final double total;

  BagliBelgeModel({
    required this.id,
    required this.ficheNo,
    required this.date,
    required this.trCode,
    required this.trCodeName,
    required this.total,
  });

  factory BagliBelgeModel.fromJson(Map<String, dynamic> json) => BagliBelgeModel(
        id: json['id'] as int,
        ficheNo: json['ficheNo'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        trCode: json['trCode'] as int? ?? 0,
        trCodeName: json['trCodeName'] as String? ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
      );
}

// ─── Detay bundle (header + satırlar + bağlı belgeler) ────────────────────
class FaturaDetayModel {
  final FaturaModel baslik;
  final List<FaturaSatirModel> satirlar;
  final List<BagliBelgeModel> irsaliyeler;
  final List<BagliBelgeModel> siparisler;
  final String genExp1;
  final String genExp2;
  final String genExp3;
  final String genExp4;

  FaturaDetayModel({
    required this.baslik,
    required this.satirlar,
    required this.irsaliyeler,
    required this.siparisler,
    this.genExp1 = '',
    this.genExp2 = '',
    this.genExp3 = '',
    this.genExp4 = '',
  });

  factory FaturaDetayModel.fromJson(Map<String, dynamic> json) =>
      FaturaDetayModel(
        baslik: FaturaModel.fromJson(json['baslik'] as Map<String, dynamic>),
        satirlar: (json['satirlar'] as List<dynamic>)
            .map((j) => FaturaSatirModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        irsaliyeler: (json['irsaliyeler'] as List<dynamic>)
            .map((j) => BagliBelgeModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        siparisler: (json['siparisler'] as List<dynamic>)
            .map((j) => BagliBelgeModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        genExp1: json['genExp1'] as String? ?? '',
        genExp2: json['genExp2'] as String? ?? '',
        genExp3: json['genExp3'] as String? ?? '',
        genExp4: json['genExp4'] as String? ?? '',
      );

  Iterable<String> get aciklamalar =>
      [genExp1, genExp2, genExp3, genExp4].where((s) => s.isNotEmpty);
}

// ─── Taslak modelleri (form için mutable) ──────────────────────────────────
class FaturaTaslakModel {
  int? id;
  int trCode;
  String? ficheNo;
  String? docCode;
  DateTime date;
  int clientRef;
  String clientCode;
  String clientTitle;
  int? sourceIndex;
  int? destIndex;
  double grossTotal;
  double totalDiscounts;
  double totalVat;
  double netTotal;
  int currencyType;          // 0=TL, >0=L_CURRENCYLIST.CURTYPE
  double exchangeRate;       // TL ise 1.0
  int? salesmanRef;
  int? payDefRef;
  // Snapshot (UI'da kod/isim göstermek için — backend dönerse map'lenir)
  String? salesmanName;
  String? payDefName;
  String? genExp1;
  String? genExp2;
  String status;
  int? transferredInvoiceId;
  DateTime? transferredAt;
  String? lastError;
  String createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<FaturaTaslakSatirModel> lines;

  FaturaTaslakModel({
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
    this.grossTotal = 0,
    this.totalDiscounts = 0,
    this.totalVat = 0,
    this.netTotal = 0,
    this.currencyType = 0,
    this.exchangeRate = 1.0,
    this.salesmanRef,
    this.payDefRef,
    this.salesmanName,
    this.payDefName,
    this.genExp1,
    this.genExp2,
    this.status = 'Draft',
    this.transferredInvoiceId,
    this.transferredAt,
    this.lastError,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
    List<FaturaTaslakSatirModel>? lines,
  }) : lines = lines ?? [];

  factory FaturaTaslakModel.fromJson(Map<String, dynamic> json) =>
      FaturaTaslakModel(
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
        grossTotal: (json['grossTotal'] as num?)?.toDouble() ?? 0,
        totalDiscounts: (json['totalDiscounts'] as num?)?.toDouble() ?? 0,
        totalVat: (json['totalVat'] as num?)?.toDouble() ?? 0,
        netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
        currencyType: json['currencyType'] as int? ?? 0,
        exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 1.0,
        salesmanRef: json['salesmanRef'] as int?,
        payDefRef: json['payDefRef'] as int?,
        genExp1: json['genExp1'] as String?,
        genExp2: json['genExp2'] as String?,
        status: json['status'] as String? ?? 'Draft',
        transferredInvoiceId: json['transferredInvoiceId'] as int?,
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
                FaturaTaslakSatirModel.fromJson(j as Map<String, dynamic>))
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
        'grossTotal': grossTotal,
        'totalDiscounts': totalDiscounts,
        'totalVat': totalVat,
        'netTotal': netTotal,
        'currencyType': currencyType,
        'exchangeRate': exchangeRate,
        'salesmanRef': salesmanRef,
        'payDefRef': payDefRef,
        'genExp1': genExp1,
        'genExp2': genExp2,
        'status': status,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  // Satırlardan toplamları yeniden hesapla
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

class FaturaTaslakSatirModel {
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

  FaturaTaslakSatirModel({
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

  factory FaturaTaslakSatirModel.fromJson(Map<String, dynamic> json) =>
      FaturaTaslakSatirModel(
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
