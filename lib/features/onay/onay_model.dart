import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Onay iş akışı modelleri — backend OnayModels.cs ile camelCase eşli.

enum OnayBelgeTip {
  fatura,
  siparis,
  irsaliye,
  tahsilat,
  masraf;

  // Backend 'tip' string'i
  String get api => switch (this) {
        OnayBelgeTip.fatura => 'fatura',
        OnayBelgeTip.siparis => 'siparis',
        OnayBelgeTip.irsaliye => 'irsaliye',
        OnayBelgeTip.tahsilat => 'tahsilat',
        OnayBelgeTip.masraf => 'masraf',
      };

  String get etiket => switch (this) {
        OnayBelgeTip.fatura => 'Fatura',
        OnayBelgeTip.siparis => 'Sipariş',
        OnayBelgeTip.irsaliye => 'İrsaliye',
        OnayBelgeTip.tahsilat => 'Tahsilat',
        OnayBelgeTip.masraf => 'Masraf',
      };

  IconData get ikon => switch (this) {
        OnayBelgeTip.fatura => Icons.receipt_long_rounded,
        OnayBelgeTip.siparis => Icons.shopping_cart_rounded,
        OnayBelgeTip.irsaliye => Icons.local_shipping_rounded,
        OnayBelgeTip.tahsilat => Icons.payments_rounded,
        OnayBelgeTip.masraf => Icons.account_balance_wallet_rounded,
      };

  Color get renk => switch (this) {
        OnayBelgeTip.fatura => AppColors.warning,
        OnayBelgeTip.siparis => AppColors.accent,
        OnayBelgeTip.irsaliye => AppColors.primary,
        OnayBelgeTip.tahsilat => AppColors.positive,
        OnayBelgeTip.masraf => AppColors.negative,
      };

  static OnayBelgeTip fromApi(String? v) => switch (v) {
        'siparis' => OnayBelgeTip.siparis,
        'irsaliye' => OnayBelgeTip.irsaliye,
        'tahsilat' => OnayBelgeTip.tahsilat,
        'masraf' => OnayBelgeTip.masraf,
        _ => OnayBelgeTip.fatura,
      };
}

class OnayBekleyen {
  final OnayBelgeTip tip;
  final int id;
  final int trCode;
  final String trCodeAd;
  final String? ficheNo;
  final String? docCode;
  final DateTime date;
  final String clientCode;
  final String clientTitle;
  final double netTotal;
  final String createdBy;
  final DateTime createdAt;

  OnayBekleyen({
    required this.tip,
    required this.id,
    required this.trCode,
    required this.trCodeAd,
    required this.ficheNo,
    required this.docCode,
    required this.date,
    required this.clientCode,
    required this.clientTitle,
    required this.netTotal,
    required this.createdBy,
    required this.createdAt,
  });

  // Gösterilecek belge no (fiş no yoksa belge kodu).
  String get belgeNo {
    if (ficheNo != null && ficheNo!.isNotEmpty) return ficheNo!;
    if (docCode != null && docCode!.isNotEmpty) return docCode!;
    return '#$id';
  }

  factory OnayBekleyen.fromJson(Map<String, dynamic> json) => OnayBekleyen(
        tip: OnayBelgeTip.fromApi(json['tip'] as String?),
        id: (json['id'] as num?)?.toInt() ?? 0,
        trCode: (json['trCode'] as num?)?.toInt() ?? 0,
        trCodeAd: json['trCodeAd'] as String? ?? '',
        ficheNo: json['ficheNo'] as String?,
        docCode: json['docCode'] as String?,
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.now(),
        clientCode: json['clientCode'] as String? ?? '',
        clientTitle: json['clientTitle'] as String? ?? '',
        netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0.0,
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class OnayOzet {
  final int fatura;
  final int siparis;
  final int irsaliye;
  final int tahsilat;
  final int masraf;

  OnayOzet({
    required this.fatura,
    required this.siparis,
    required this.irsaliye,
    this.tahsilat = 0,
    this.masraf = 0,
  });

  int get toplam => fatura + siparis + irsaliye + tahsilat + masraf;

  factory OnayOzet.fromJson(Map<String, dynamic> json) => OnayOzet(
        fatura: (json['fatura'] as num?)?.toInt() ?? 0,
        siparis: (json['siparis'] as num?)?.toInt() ?? 0,
        irsaliye: (json['irsaliye'] as num?)?.toInt() ?? 0,
        tahsilat: (json['tahsilat'] as num?)?.toInt() ?? 0,
        masraf: (json['masraf'] as num?)?.toInt() ?? 0,
      );
}
