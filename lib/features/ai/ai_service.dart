import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'ai_model.dart';

/// Yapay zeka asistanı servisi — backend `/api/ai/chat` ile konuşur.
/// Tool-use döngüsü tamamen backend'de döner; burada sadece metin gidip gelir.
class AiService {
  final Dio _dio = apiClient.dio;

  /// Kullanıcının mesajını geçmişle birlikte gönderir, asistan cevabını döner.
  Future<AiChatResponse> chat(String message, List<AiMessage> history) async {
    try {
      final response = await _dio.post(
        '/api/Ai/chat',
        data: {
          'message': message,
          'history': history.map((m) => m.toJson()).toList(),
        },
      );
      return AiChatResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Yapay zeka servisine bağlanılamadı';
    }
    if (e.response?.statusCode == 400) {
      return 'İstek geçersiz';
    }
    return 'Beklenmedik hata: ${e.message}';
  }
}

final aiService = AiService();
