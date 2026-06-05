// Yapay zeka asistanı modelleri — backend `AiDtos.cs` karşılıkları.

/// Sohbetteki tek bir mesaj (kullanıcı veya asistan).
class AiMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final AiAction? action; // sadece asistan mesajlarında dolu olabilir

  const AiMessage({required this.role, required this.text, this.action});

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

/// Backend'den dönen sohbet cevabı.
class AiChatResponse {
  final String reply;
  final AiAction? action;

  const AiChatResponse({required this.reply, this.action});

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      reply: json['reply'] as String? ?? '',
      action: json['action'] == null
          ? null
          : AiAction.fromJson(json['action'] as Map<String, dynamic>),
    );
  }
}

/// Asistanın önerdiği aksiyon — ilgili form ön-dolu açılır.
class AiAction {
  final String type; // 'fatura' | 'siparis' | 'none'
  final int? trCode; // belge alt türü (LOGO TRCODE)
  final AiCariRef? cari;
  final List<AiLineSeed> lines;
  final DateTime? vade;

  const AiAction({
    required this.type,
    this.trCode,
    this.cari,
    this.lines = const [],
    this.vade,
  });

  bool get isFatura => type == 'fatura';
  bool get isSiparis => type == 'siparis';
  bool get isUygulanabilir => (isFatura || isSiparis) && cari != null;

  // Satınalma türleri: fatura 31/34/36/42/43/56, sipariş 2.
  bool get isSatinalma => trCode == 2 || trCode == 31 || trCode == 34 ||
      trCode == 36 || trCode == 42 || trCode == 43 || trCode == 56;

  factory AiAction.fromJson(Map<String, dynamic> json) {
    final vadeStr = json['vade'] as String?;
    return AiAction(
      type: json['type'] as String? ?? 'none',
      trCode: json['trCode'] as int?,
      cari: json['cari'] == null
          ? null
          : AiCariRef.fromJson(json['cari'] as Map<String, dynamic>),
      lines: (json['lines'] as List<dynamic>? ?? [])
          .map((e) => AiLineSeed.fromJson(e as Map<String, dynamic>))
          .toList(),
      vade: (vadeStr == null || vadeStr.isEmpty) ? null : DateTime.tryParse(vadeStr),
    );
  }
}

/// Aksiyondaki cari referansı.
class AiCariRef {
  final int id;
  final String kod;
  final String unvan;

  const AiCariRef({required this.id, required this.kod, required this.unvan});

  factory AiCariRef.fromJson(Map<String, dynamic> json) {
    return AiCariRef(
      id: json['id'] as int? ?? 0,
      kod: json['kod'] as String? ?? '',
      unvan: json['unvan'] as String? ?? '',
    );
  }
}

/// Forma önceden eklenecek satır tohumu (malzeme + miktar + opsiyonel fiyat).
class AiLineSeed {
  final int stokRef;
  final String kod;
  final String ad;
  final String birim;
  final double miktar;
  final double? fiyat;

  const AiLineSeed({
    required this.stokRef,
    required this.kod,
    required this.ad,
    this.birim = '',
    this.miktar = 1,
    this.fiyat,
  });

  factory AiLineSeed.fromJson(Map<String, dynamic> json) {
    return AiLineSeed(
      stokRef: json['stokRef'] as int? ?? 0,
      kod: json['kod'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      birim: json['birim'] as String? ?? '',
      miktar: (json['miktar'] as num?)?.toDouble() ?? 1,
      fiyat: (json['fiyat'] as num?)?.toDouble(),
    );
  }
}
