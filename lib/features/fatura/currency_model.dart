// Lookup tablolarının ortak hafif modeli (SLSMAN/PAYPLANS/SHIPINFO için)
class LookupItem {
  final int id;
  final String code;
  final String name;
  const LookupItem({required this.id, required this.code, required this.name});

  factory LookupItem.fromJson(Map<String, dynamic> json) => LookupItem(
        id: json['id'] as int? ?? 0,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) => other is LookupItem && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

// L_CURRENCYLIST projection (backend Currency DTO aynası)
class CurrencyModel {
  final int curType;       // 1=USD, 2=DEM vb. (TL=0 — özel, listede gelmez)
  final String curCode;    // "USD"
  final String curName;    // "ABD Doları"

  const CurrencyModel({
    required this.curType,
    required this.curCode,
    required this.curName,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) => CurrencyModel(
        curType: json['curType'] as int? ?? 0,
        curCode: json['curCode'] as String? ?? '',
        curName: json['curName'] as String? ?? '',
      );

  // Sabit TL — listenin başına manuel eklenir
  static const tl = CurrencyModel(curType: 0, curCode: 'TL', curName: 'Türk Lirası');
}

// L_DAILYEXCHANGES'ten en güncel kur
class ExchangeRateModel {
  final int curType;
  final String curCode;
  // RATES1=banknot alış, RATES2=banknot satış, RATES3=döviz alış, RATES4=döviz satış
  final double rates1;
  final double rates2;
  final double rates3;
  final double rates4;
  final bool hasData;

  const ExchangeRateModel({
    required this.curType,
    required this.curCode,
    required this.rates1,
    required this.rates2,
    required this.rates3,
    required this.rates4,
    required this.hasData,
  });

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) => ExchangeRateModel(
        curType: json['curType'] as int? ?? 0,
        curCode: json['curCode'] as String? ?? '',
        rates1: (json['rates1'] as num?)?.toDouble() ?? 0,
        rates2: (json['rates2'] as num?)?.toDouble() ?? 0,
        rates3: (json['rates3'] as num?)?.toDouble() ?? 0,
        rates4: (json['rates4'] as num?)?.toDouble() ?? 0,
        hasData: json['hasData'] as bool? ?? false,
      );

  // Varsayılan kur = banknot satış (en yaygın kullanılan)
  double get defaultRate => rates2 > 0 ? rates2 : (rates4 > 0 ? rates4 : rates1);
}
