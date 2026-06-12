import 'package:flutter/material.dart';

// Cari hesap fişi (tahsilat / ödeme) tür tanımları.
// trCode değerleri LOGO CLFICHE.TRCODE ile birebir eşleşir (bkz. DB ref. Bölüm 23).
enum TahsilatTuru {
  nakitTahsilat(1, 'Nakit Tahsilat', false),
  krediKarti(70, 'Kredi Kartı Fişi', false),
  nakitOdeme(2, 'Nakit Ödeme', true);

  const TahsilatTuru(this.trCode, this.adi, this.isOdeme);

  final int trCode;
  final String adi;
  // true = ödeme (para çıkışı, CLFLINE.SIGN=0 borç)
  // false = tahsilat (para girişi, CLFLINE.SIGN=1 alacak)
  final bool isOdeme;

  // CLFLINE.SIGN: 0=Borç, 1=Alacak
  int get sign => isOdeme ? 0 : 1;

  IconData get ikon => switch (this) {
        TahsilatTuru.nakitTahsilat => Icons.payments_rounded,
        TahsilatTuru.krediKarti => Icons.credit_card_rounded,
        TahsilatTuru.nakitOdeme => Icons.account_balance_wallet_rounded,
      };

  static TahsilatTuru fromTrCode(int code) =>
      values.firstWhere((t) => t.trCode == code,
          orElse: () => TahsilatTuru.nakitTahsilat);
}

// Taslak tahsilat fişi — backend (/api/CollectionDraft) ile alışveriş modeli.
// Tek para hareketi taşır; LOGO tarafında CLFICHE + tek CLFLINE'a aktarılır.
class TahsilatTaslakModel {
  int? id;
  int trCode;
  String? ficheNo; // LOGO fiş no (aktarımda atanır)
  String? docCode; // Belge no (manuel)
  DateTime date;
  int clientRef;
  String clientCode;
  String clientTitle;
  double amount;
  int currencyType; // 0=TL, >0=L_CURRENCYLIST.CURTYPE
  double exchangeRate; // TL ise 1.0
  String? aciklama; // CLFLINE.LINEEXP / GENEXP1
  // Şema-driven ek alanlar (firmaya özel zorunluluklar: BRANCH, DEPARTMENT vb.)
  Map<String, dynamic>? extraFields;
  String status; // 'Draft' | 'Transferred' | 'Failed'
  String? approvalStatus; // 'Pending' | 'Approved' | 'Rejected'
  String? rejectReason; // reddedildiyse gerekçe
  int? transferredFicheId; // LOGO CLFICHE.LOGICALREF (aktarım sonrası)
  DateTime? transferredAt;
  String? lastError;
  String createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;

  TahsilatTaslakModel({
    this.id,
    required this.trCode,
    this.ficheNo,
    this.docCode,
    required this.date,
    required this.clientRef,
    required this.clientCode,
    required this.clientTitle,
    this.amount = 0,
    this.currencyType = 0,
    this.exchangeRate = 1.0,
    this.aciklama,
    this.extraFields,
    this.status = 'Draft',
    this.approvalStatus,
    this.rejectReason,
    this.transferredFicheId,
    this.transferredAt,
    this.lastError,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  TahsilatTuru get tur => TahsilatTuru.fromTrCode(trCode);
  bool get isOdeme => tur.isOdeme;

  // Onay durumu — aktarım yalnızca onaylanınca açılır (fatura akışıyla aynı).
  bool get isOnaylandi => approvalStatus == 'Approved';
  bool get isReddedildi => approvalStatus == 'Rejected';
  bool get isOnayBekliyor => approvalStatus == 'Pending';

  factory TahsilatTaslakModel.fromJson(Map<String, dynamic> json) =>
      TahsilatTaslakModel(
        id: json['id'] as int?,
        trCode: json['trCode'] as int,
        ficheNo: json['ficheNo'] as String?,
        docCode: json['docCode'] as String?,
        date: DateTime.parse(json['date'] as String),
        clientRef: json['clientRef'] as int,
        clientCode: json['clientCode'] as String? ?? '',
        clientTitle: json['clientTitle'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currencyType: json['currencyType'] as int? ?? 0,
        exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 1.0,
        aciklama: json['aciklama'] as String?,
        extraFields: json['extraFields'] as Map<String, dynamic>?,
        status: json['status'] as String? ?? 'Draft',
        approvalStatus: json['approvalStatus'] as String?,
        rejectReason: json['rejectReason'] as String?,
        transferredFicheId: json['transferredFicheId'] as int?,
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
        'amount': amount,
        'currencyType': currencyType,
        'exchangeRate': exchangeRate,
        'aciklama': aciklama,
        if (extraFields != null) 'extraFields': extraFields,
        'status': status,
      };
}

// ─── Şema-driven form ───────────────────────────────────────────────────────
// Zorunlu/opsiyonel alanlar uygulamaya HARDCODE EDİLMEZ. Backend, Logo REST'e
// probe (yoklama) yapıp dönen validation hatasından firmaya özel zorunlulukları
// öğrenir ve bu şemayı döner. Cari/tutar/tarih/tür formda zaten standart; şema
// yalnızca EK alanları (BRANCH, DEPARTMENT, özel alanlar) bildirir.

enum TahsilatAlanTipi { metin, sayi, tarih, secim }

class TahsilatAlan {
  final String key;
  final String label;
  final bool zorunlu;
  final TahsilatAlanTipi tip;
  final String? varsayilan;
  final List<TahsilatSecenek> secenekler;

  const TahsilatAlan({
    required this.key,
    required this.label,
    this.zorunlu = false,
    this.tip = TahsilatAlanTipi.metin,
    this.varsayilan,
    this.secenekler = const [],
  });

  factory TahsilatAlan.fromJson(Map<String, dynamic> json) => TahsilatAlan(
        key: json['key'] as String,
        label: json['label'] as String? ?? json['key'] as String,
        zorunlu: json['zorunlu'] as bool? ?? json['required'] as bool? ?? false,
        tip: _tipFromString(json['tip'] as String? ?? json['type'] as String?),
        varsayilan: json['varsayilan'] as String? ?? json['default'] as String?,
        secenekler: (json['secenekler'] as List<dynamic>? ??
                json['options'] as List<dynamic>? ??
                [])
            .map((j) => TahsilatSecenek.fromJson(j as Map<String, dynamic>))
            .toList(),
      );

  static TahsilatAlanTipi _tipFromString(String? s) => switch (s) {
        'sayi' || 'number' => TahsilatAlanTipi.sayi,
        'tarih' || 'date' => TahsilatAlanTipi.tarih,
        'secim' || 'select' => TahsilatAlanTipi.secim,
        _ => TahsilatAlanTipi.metin,
      };
}

class TahsilatSecenek {
  final String deger;
  final String etiket;
  const TahsilatSecenek(this.deger, this.etiket);

  factory TahsilatSecenek.fromJson(Map<String, dynamic> json) => TahsilatSecenek(
        (json['deger'] ?? json['value']).toString(),
        (json['etiket'] ?? json['label'] ?? json['value']).toString(),
      );
}

class TahsilatSema {
  // Standart alanların dışındaki, firmaya özel EK zorunlu/opsiyonel alanlar.
  final List<TahsilatAlan> ekAlanlar;
  const TahsilatSema(this.ekAlanlar);

  factory TahsilatSema.fromJson(Map<String, dynamic> json) => TahsilatSema(
        (json['fields'] as List<dynamic>? ?? json['ekAlanlar'] as List<dynamic>? ?? [])
            .map((j) => TahsilatAlan.fromJson(j as Map<String, dynamic>))
            .toList(),
      );

  // Backend şema endpoint'i henüz yoksa/stub ise: ek zorunlu alan yok varsayılır.
  // Gerçek zorunluluklar LOGO'ya aktarım anında doğrulanır.
  factory TahsilatSema.baseline() => const TahsilatSema([]);
}
