import 'package:dio/dio.dart';
import 'message_gateway.dart';

/// Infobip — SMS, RCS e WhatsApp com cobertura global e escritório no Brasil.
/// Docs: https://www.infobip.com/docs/api
class InfobipGateway implements MessageGateway {
  late Dio _dio;
  late String _from;

  @override
  String get providerType => 'infobip';

  @override
  List<MessageChannel> get supportedChannels =>
      [MessageChannel.sms, MessageChannel.rcs, MessageChannel.whatsapp];

  @override
  Future<void> initialize(Map<String, dynamic> credentials) async {
    final apiKey = credentials['api_key'] as String;
    final baseUrl = credentials['base_url'] as String; // e.g. xxxxx.api.infobip.com
    _from = credentials['from'] as String;
    _dio = Dio(BaseOptions(
      baseUrl: 'https://$baseUrl',
      headers: {'Authorization': 'App $apiKey', 'Content-Type': 'application/json'},
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
      switch (channel) {
        case MessageChannel.sms:
          return _sendSms(to, body);
        case MessageChannel.rcs:
          return _sendRcs(to, body, mediaUrl);
        case MessageChannel.whatsapp:
          return _sendWhatsApp(to, body, mediaUrl);
      }
    } on DioException catch (e) {
      return GatewayResult.err(
        e.response?.data.toString() ?? e.message ?? 'Erro',
        e.response?.data as Map<String, dynamic>?,
      );
    }
  }

  Future<GatewayResult> _sendSms(String to, String body) async {
    final resp = await _dio.post('/sms/2/text/advanced', data: {
      'messages': [
        {'from': _from, 'destinations': [{'to': to}], 'text': body}
      ]
    });
    final msgs = resp.data['messages'] as List?;
    final id = msgs?.isNotEmpty == true ? msgs![0]['messageId'] as String? : null;
    return GatewayResult.ok(id ?? '', resp.data as Map<String, dynamic>);
  }

  Future<GatewayResult> _sendRcs(String to, String body, String? mediaUrl) async {
    final resp = await _dio.post('/rcs/1/message', data: {
      'from': _from,
      'to': to,
      'content': {'text': body},
    });
    final id = resp.data['messageId'] as String?;
    return GatewayResult.ok(id ?? '', resp.data as Map<String, dynamic>);
  }

  Future<GatewayResult> _sendWhatsApp(String to, String body, String? mediaUrl) async {
    final resp = await _dio.post('/whatsapp/1/message/text', data: {
      'from': _from,
      'to': to,
      'content': {'text': body},
    });
    final id = resp.data['messageId'] as String?;
    return GatewayResult.ok(id ?? '', resp.data as Map<String, dynamic>);
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
    for (final number in numbers) {
      results.add(await sendMessage(to: number, body: body, channel: channel, mediaUrl: mediaUrl));
      if (delayMs > 0) await Future.delayed(Duration(milliseconds: delayMs));
    }
    return results;
  }

  @override
  Future<DeliveryStatus> checkStatus(String externalId) async {
    try {
      final resp = await _dio.get('/sms/1/reports', queryParameters: {'messageId': externalId});
      final results = resp.data['results'] as List?;
      if (results == null || results.isEmpty) return DeliveryStatus.unknown;
      final status = results[0]['status']['groupName'] as String? ?? '';
      return _mapStatus(status);
    } catch (_) {
      return DeliveryStatus.unknown;
    }
  }

  @override
  Future<bool> validateCredentials(Map<String, dynamic> credentials) async {
    try {
      await initialize(credentials);
      await _dio.get('/account/1/balance');
      return true;
    } catch (_) {
      return false;
    }
  }

  DeliveryStatus _mapStatus(String s) => switch (s.toUpperCase()) {
        'DELIVERED' => DeliveryStatus.delivered,
        'SEEN' => DeliveryStatus.read,
        'PENDING' || 'ACCEPTED' => DeliveryStatus.pending,
        'UNDELIVERABLE' || 'REJECTED' => DeliveryStatus.failed,
        _ => DeliveryStatus.unknown,
      };
}
