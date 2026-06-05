class CariHareket {
  final int id;
  final DateTime date;
  final int transactionType;
  final String transactionTypeName;
  final String description;
  final double debit;
  final double credit;
  final String documentNo;
  final String transactionNo;

  CariHareket({
    required this.id,
    required this.date,
    required this.transactionType,
    required this.transactionTypeName,
    required this.description,
    required this.debit,
    required this.credit,
    required this.documentNo,
    required this.transactionNo,
  });

  bool get isTahsilat => credit > 0;
  double get netAmount => credit - debit;

  factory CariHareket.fromJson(Map<String, dynamic> json) {
    return CariHareket(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      transactionType: json['transactionType'] as int,
      transactionTypeName: json['transactionTypeName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      documentNo: json['documentNo'] as String? ?? '',
      transactionNo: json['transactionNo'] as String? ?? '',
    );
  }
}