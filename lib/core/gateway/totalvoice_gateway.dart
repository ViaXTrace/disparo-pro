import 'package:dio/dio.dart';
import 'message_gateway.dart';

/// TotalVoice (Zenvia Voice) — SMS brasileiro, muito usado em automações nacionais.
/// Docs: https://totalvoice.github.io/totalvoice-docs/
class TotalVoiceGateway implements MessageGateway {
  late Dio _dio;

  @override
  String get providerType => 'totalvoice';

  @override
  List<MessageChannel> get supportedChannels => [MessageChannel.sms];

  @override
  Future<void> initialize(Map<String, dynamic> credentials) async {
    final token = credentials['access_token'] as String;
    _dio = Dio(BaseOptions(
      baseUrl: 'https://voice-api.zenvia.com',
      headers: {'Access-Token': token, 'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  @override
  Future<GatewayResult> sendMessage({
    required String to,
    required String body,
    required MessageChannel channel,
    String? mediaUrl,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final resp = await _dio.post('/sms', data: {
        'numero_destino': to,
        'mensagem': body,
      });
      final id = resp.data['dados']?['id']?.toString();
      return GatewayResult.ok(id ?? '', resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return GatewayResult.err(
          e.response?.data.toString() ?? e.message ?? 'Erro');
    }
  }

  @override
  Future<List<GatewayResult>> sendBatch({
    required List<String> numbers,
    required String body,
    required MessageChannel channel,
    String? mediaUrl,
    int delayMs = 200,
  }) async {
    final results = <GatewayResult>[];
    for (final n in numbers) {
      results.add(await sendMessage(
          to: n, body: body, channel: channel, mediaUrl: mediaUrl));
      if (delayMs > 0) await Future.delayed(Duration(milliseconds: delayMs));
    }
    return results;
  }

  @override
  Future<DeliveryStatus> checkStatus(String externalId) async {
    try {
      final resp = await _dio.get('/sms/$externalId');
      final status =
          resp.data['dados']?['status_envio'] as String? ?? '';
      return _mapStatus(status);
    } catch (_) {
      return DeliveryStatus.unknown;
    }
  }

  @override
  Future<bool> validateCredentials(Map<String, dynamic> credentials) async {
    try {
      await initialize(credentials);
      await _dio.get('/conta');
      return true;
    } catch (_) {
      return false;
    }
  }

  DeliveryStatus _mapStatus(String s) => switch (s.toLowerCase()) {
        'enviada' => DeliveryStatus.sent,
        'entregue' => DeliveryStatus.delivered,
        'erro' || 'falha' => DeliveryStatus.failed,
        _ => DeliveryStatus.pending,
      };
}
