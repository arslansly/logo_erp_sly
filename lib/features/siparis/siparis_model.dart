import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../fatura/fatura_model.dart' show BagliBelgeModel;

// ─── Sipariş türleri (ORFICHE.TRCODE) ──────────────────────────────────────
enum SiparisTuru {
  satis(1, 'Satış Siparişi', 'Satış'),       // alınan sipariş
  satinalma(2, 'Satınalma Siparişi', 'Satınalma');

  final int trCode;
  final String adi;
  final String kategori;
  const SiparisTuru(this.trCode, this.adi, this.kategori);

  static SiparisTuru? fromTrCode(int code) {
    for (final t in SiparisTuru.values) {
      if (t.trCode == code) return t;
    }
    return null;
  }

  IconData get ikon => switch (kategori) {
        'Satış' => Icons.trending_up_rounded,
        'Satınalma' => Icons.trending_down_rounded,
        _ => Icons.assignment_rounded,
      };

  Color get renk => switch (kategori) {
        'Satış' => AppColors.positive,
        'Satınalma' => AppColors.cyan,
        _ => AppColors.slate500,
      };
}

// ─── Sipariş onay durumu (ORFICHE.STATUS — ham/onay durumu) ────────────────
// Bu kurulumda canlı doğrulama: 1=Öneri, 2=Sevkedilemez, 4=Sevkedilebilir.
// (Sevk/teslim durumu artık satır miktarlarından türetilir → [SiparisSevkDurumu].)
enum SiparisDurumu {
  oneri(1, 'Öneri'),
  sevkedilemez(2, 'Sevkedilemez'),
  sevkedilebilir(4, 'Sevkedilebilir');

  final int kod;
  final String adi;
  const SiparisDurumu(this.kod, this.adi);

  static SiparisDurumu? fromKod(int kod) {
    // 3 ve 4 her ikisi de "Sevkedilebilir/Onaylı" anlamına gelir.
    if (kod == 3 || kod == 4) return SiparisDurumu.sevkedilebilir;
    for (final d in SiparisDurumu.values) {
      if (d.kod == kod) return d;
    }
    return null;
  }

  Color get renk => switch (this) {
        SiparisDurumu.oneri => AppColors.slate500,
        SiparisDurumu.sevkedilemez => AppColors.negative,
        SiparisDurumu.sevkedilebilir => AppColors.accent,
      };

  IconData get ikon => switch (this) {
        SiparisDurumu.oneri => Icons.lightbulb_outline_rounded,
        SiparisDurumu.sevkedilemez => Icons.block_rounded,
        SiparisDurumu.sevkedilebilir => Icons.check_circle_outline_rounded,
      };
}

// ─── Sevk/teslim durumu (satır miktarlarından türetilir) ───────────────────
// Bekleyen yoksa = tamamı sevkedildi; kısmen gönderildiyse = sevkediliyor;
// hiç gönderilmediyse = ham (onay durumu gösterilir).
enum SiparisSevkDurumu {
  ham,
  sevkediliyor,
  sevkedildi;

  String get adi => switch (this) {
        SiparisSevkDurumu.ham => '',
        SiparisSevkDurumu.sevkediliyor => 'Sevkediliyor',
        SiparisSevkDurumu.sevkedildi => 'Sevkedildi',
      };

  Color get renk => switch (this) {
        SiparisSevkDurumu.ham => AppColors.slate500,
        SiparisSevkDurumu.sevkediliyor => AppColors.cyan,
        SiparisSevkDurumu.sevkedildi => AppColors.positive,
      };

  IconData get ikon => switch (this) {
        SiparisSevkDurumu.ham => Icons.help_outline_rounded,
        SiparisSevkDurumu.sevkediliyor => Icons.local_shipping_outlined,
        SiparisSevkDurumu.sevkedildi => Icons.local_shipping_rounded,
      };
}

// ─── Liste / kart modeli ──────────────────────────────────────────────────
class SiparisModel {
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
  final int status;
  final String statusName;
  final int cancelled;
  final int closed;
  // Satırlardan türetilen sevk durumu (backend ORFLINE aggregate)
  final double toplamMiktar;
  final double sevkMiktar;
  final double bekleyenMiktar;
  // Taslak akışı için
  final bool isDraft;
  final String draftStatus; // 'Draft' | 'Transferred' | 'Failed'
  final String? lastError;
  final String? approvalStatus; // 'Pending' | 'Approved' | 'Rejected'

  SiparisModel({
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
    required this.status,
    required this.statusName,
    required this.cancelled,
    required this.closed,
    this.toplamMiktar = 0,
    this.sevkMiktar = 0,
    this.bekleyenMiktar = 0,
    this.isDraft = false,
    this.draftStatus = '',
    this.lastError,
    this.approvalStatus,
  });

  factory SiparisModel.fromJson(Map<String, dynamic> json) => SiparisModel(
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
        status: json['status'] as int? ?? 0,
        statusName: json['statusName'] as String? ?? '',
        cancelled: json['cancelled'] as int? ?? 0,
        closed: json['closed'] as int? ?? 0,
        toplamMiktar: (json['toplamMiktar'] as num?)?.toDouble() ?? 0,
        sevkMiktar: (json['sevkMiktar'] as num?)?.toDouble() ?? 0,
        bekleyenMiktar: (json['bekleyenMiktar'] as num?)?.toDouble() ?? 0,
        isDraft: json['isDraft'] as bool? ?? false,
        draftStatus: json['draftStatus'] as String? ?? '',
        lastError: json['lastError'] as String?,
        approvalStatus: json['approvalStatus'] as String?,
      );

  SiparisTuru? get tur => SiparisTuru.fromTrCode(trCode);
  SiparisDurumu? get durum => SiparisDurumu.fromKod(status);

  // Satır miktarlarından türetilen sevk durumu.
  SiparisSevkDurumu get sevkDurumu {
    if (toplamMiktar > 0 && bekleyenMiktar <= 0.0001) {
      return SiparisSevkDurumu.sevkedildi;
    }
    if (sevkMiktar > 0.0001) return SiparisSevkDurumu.sevkediliyor;
    return SiparisSevkDurumu.ham;
  }

  // Kartta/detayda gösterilecek durum: sevk durumu varsa onu, yoksa ham onay durumu.
  String get durumEtiketi => sevkDurumu == SiparisSevkDurumu.ham
      ? (durum?.adi ?? (statusName.isEmpty ? 'Durum ($status)' : statusName))
      : sevkDurumu.adi;

  Color get durumRenk => sevkDurumu == SiparisSevkDurumu.ham
      ? (durum?.renk ?? AppColors.slate500)
      : sevkDurumu.renk;

  IconData get durumIkon => sevkDurumu == SiparisSevkDurumu.ham
      ? (durum?.ikon ?? Icons.help_outline_rounded)
      : sevkDurumu.ikon;

  bool get isKapali => closed != 0;
  bool get isIptal => cancelled != 0;
  bool get isTaslak => isDraft && draftStatus == 'Draft';
  // Onay durumu — yalnızca taslakta anlamlı
  bool get isOnayBekliyor => isDraft && approvalStatus == 'Pending';
  bool get isOnaylandi => isDraft && approvalStatus == 'Approved';
  bool get isReddedildi => isDraft && approvalStatus == 'Rejected';
  bool get isAktarildi => !isDraft || draftStatus == 'Transferred';
  bool get isHatali => isDraft && draftStatus == 'Failed';
}

// ─── Sipariş satırı ───────────────────────────────────────────────────────
class SiparisSatirModel {
  final int id;
  final int lineNo;
  final int lineType;
  final String lineTypeName;
  final int? stockRef;
  final String stockCode;
  final String stockName;
  final String uomCode;
  final double amount;
  final double shippedAmount;
  final double price;
  final double vatRate;
  final double total;
  final double vatAmount;
  final double lineNet;
  final double discount;
  final DateTime? dueDate;
  final int closed;
  final int status;
  final String lineDescription;

  SiparisSatirModel({
    required this.id,
    required this.lineNo,
    required this.lineType,
    required this.lineTypeName,
    this.stockRef,
    required this.stockCode,
    required this.stockName,
    required this.uomCode,
    required this.amount,
    required this.shippedAmount,
    required this.price,
    required this.vatRate,
    required this.total,
    required this.vatAmount,
    required this.lineNet,
    required this.discount,
    this.dueDate,
    required this.closed,
    required this.status,
    required this.lineDescription,
  });

  factory SiparisSatirModel.fromJson(Map<String, dynamic> json) =>
      SiparisSatirModel(
        id: json['id'] as int? ?? 0,
        lineNo: json['lineNo'] as int? ?? 0,
        lineType: json['lineType'] as int? ?? 0,
        lineTypeName: json['lineTypeName'] as String? ?? '',
        stockRef: json['stockRef'] as int?,
        stockCode: json['stockCode'] as String? ?? '',
        stockName: json['stockName'] as String? ?? '',
        uomCode: json['uomCode'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        shippedAmount: (json['shippedAmount'] as num?)?.toDouble() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0,
        lineNet: (json['lineNet'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        dueDate: (json['dueDate'] as String?) != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        closed: json['closed'] as int? ?? 0,
        status: json['status'] as int? ?? 0,
        lineDescription: json['lineDescription'] as String? ?? '',
      );

  bool get isKapali => closed != 0;

  // Kapalı satır tamamı sevkedilmiş sayılır (SHIPPEDAMOUNT güncellenmese de).
  double get etkinSevk => isKapali ? amount : shippedAmount;

  // Bekleyen miktar (kapalı satırda 0).
  double get bekleyenMiktar =>
      isKapali ? 0 : (amount - shippedAmount).clamp(0, double.infinity);

  double get sevkOrani => amount == 0
      ? (isKapali ? 1 : 0)
      : (etkinSevk / amount).clamp(0, 1);
}

// ─── Detay bundle ─────────────────────────────────────────────────────────
class SiparisDetayModel {
  final SiparisModel baslik;
  final List<SiparisSatirModel> satirlar;
  final List<BagliBelgeModel> irsaliyeler; // bu siparişe bağlı sevkiyatlar
  final String genExp1;
  final String genExp2;

  SiparisDetayModel({
    required this.baslik,
    required this.satirlar,
    this.irsaliyeler = const [],
    this.genExp1 = '',
    this.genExp2 = '',
  });

  factory SiparisDetayModel.fromJson(Map<String, dynamic> json) =>
      SiparisDetayModel(
        baslik: SiparisModel.fromJson(json['baslik'] as Map<String, dynamic>),
        satirlar: (json['satirlar'] as List<dynamic>)
            .map((j) => SiparisSatirModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        irsaliyeler: (json['irsaliyeler'] as List<dynamic>? ?? [])
            .map((j) => BagliBelgeModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        genExp1: json['genExp1'] as String? ?? '',
        genExp2: json['genExp2'] as String? ?? '',
      );

  Iterable<String> get aciklamalar =>
      [genExp1, genExp2].where((s) => s.isNotEmpty);
}

// ─── Taslak modelleri (form için mutable) ──────────────────────────────────
// Fatura taslağıyla paralel; ek olarak fiş bazlı `dueDate` (termin) ve
// satır bazlı `dueDate` override içerir. LogoStatus backend'de hep 1 (Öneri).
class SiparisTaslakModel {
  int? id;
  int trCode;
  String? ficheNo;
  String? docCode;
  DateTime date;
  DateTime? dueDate; // fiş bazlı varsayılan termin
  int clientRef;
  String clientCode;
  String clientTitle;
  double grossTotal;
  double totalDiscounts;
  double totalVat;
  double netTotal;
  int currencyType; // 0=TL, >0=L_CURRENCYLIST.CURTYPE
  double exchangeRate; // TL ise 1.0
  int? salesmanRef;
  int? payDefRef;
  String? genExp1;
  String? genExp2;
  String status;
  int? transferredOrderId;
  DateTime? transferredAt;
  String? lastError;
  String createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<SiparisTaslakSatirModel> lines;

  SiparisTaslakModel({
    this.id,
    required this.trCode,
    this.ficheNo,
    this.docCode,
    required this.date,
    this.dueDate,
    required this.clientRef,
    required this.clientCode,
    required this.clientTitle,
    this.grossTotal = 0,
    this.totalDiscounts = 0,
    this.totalVat = 0,
    this.netTotal = 0,
    this.currencyType = 0,
    this.exchangeRate = 1.0,
    this.salesmanRef,
    this.payDefRef,
    this.genExp1,
    this.genExp2,
    this.status = 'Draft',
    this.transferredOrderId,
    this.transferredAt,
    this.lastError,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
    List<SiparisTaslakSatirModel>? lines,
  }) : lines = lines ?? [];

  factory SiparisTaslakModel.fromJson(Map<String, dynamic> json) =>
      SiparisTaslakModel(
        id: json['id'] as int?,
        trCode: json['trCode'] as int,
        ficheNo: json['ficheNo'] as String?,
        docCode: json['docCode'] as String?,
        date: DateTime.parse(json['date'] as String),
        dueDate: (json['dueDate'] as String?) != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        clientRef: json['clientRef'] as int,
        clientCode: json['clientCode'] as String? ?? '',
        clientTitle: json['clientTitle'] as String? ?? '',
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
        transferredOrderId: json['transferredOrderId'] as int?,
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
                SiparisTaslakSatirModel.fromJson(j as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'trCode': trCode,
        'ficheNo': ficheNo,
        'docCode': docCode,
        'date': date.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'clientRef': clientRef,
        'clientCode': clientCode,
        'clientTitle': clientTitle,
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

class SiparisTaslakSatirModel {
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
  DateTime? dueDate; // satır bazlı termin override
  String? lineDescription;

  SiparisTaslakSatirModel({
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
    this.dueDate,
    this.lineDescription,
  });

  factory SiparisTaslakSatirModel.fromJson(Map<String, dynamic> json) =>
      SiparisTaslakSatirModel(
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
        dueDate: (json['dueDate'] as String?) != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
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
        'dueDate': dueDate?.toIso8601String(),
        'lineDescription': lineDescription,
      };

  void recomputeTotals() {
    total = amount * price;
    final tabani = total - discount;
    vatAmount = tabani * vatRate / 100;
    lineNet = tabani + vatAmount;
  }
}
