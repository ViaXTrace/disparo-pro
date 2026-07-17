import 'package:dio/dio.dart';
import 'message_gateway.dart';

/// Custom Webhook — para provedores não listados ou gateways próprios.
/// Configura método HTTP, URL, headers e template de payload via JSON.
class CustomWebhookGateway implements MessageGateway {
  late Dio _dio;
  late String _url;
  late String _method;
  late Map<String, String> _headers;
  late String _payloadTemplate; // JSON com {{to}}, {{body}}, {{channel}} como vars

  @override
  String get providerType => 'custom_webhook';

  @override
  List<MessageChannel> get supportedChannels =>
      [MessageChannel.sms, MessageChannel.rcs, MessageChannel.whatsapp];

  @override
  Future<void> initialize(Map<String, dynamic> credentials) async {
    _url = credentials['url'] as String;
    _method = (credentials['method'] as String? ?? 'POST').toUpperCase();
    _headers = Map<String, String>.from(
        credentials['headers'] as Map? ?? {'Content-Type': 'application/json'});
    _payloadTemplate = credentials['payload_template'] as String? ??
        '{"to":"{{to}}","body":"{{body}}","channel":"{{channel}}"}';
    _dio = Dio(BaseOptions(
      headers: _headers,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  String _buildPayload(String to, String body, MessageChannel channel) {
    return _payloadTemplate
        .replaceAll('{{to}}', to)
        .replaceAll('{{body}}', body.replaceAll('"', r'\"'))
        .replaceAll('{{channel}}', channel.name);
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
      final payload = _buildPayload(to, body, channel);
      Response<dynamic> resp;
      if (_method == 'GET') {
        resp = await _dio.get(_url, queryParameters: {'to': to, 'body': body});
      } else {
        resp = await _dio.post(_url, data: payload);
      }
      final id = resp.data is Map ? (resp.data['id'] ?? resp.data['messageId'] ?? '').toString() : '';
      return GatewayResult.ok(id, resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : null);
    } on DioException catch (e) {
      return GatewayResult.err(
          e.response?.data?.toString() ?? e.message ?? 'Erro no webhook');
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
      results.add(await sendMessage(to: n, body: body, channel: channel));
      if (delayMs > 0) await Future.delayed(Duration(milliseconds: delayMs));
    }
    return results;
  }

  @override
  Future<DeliveryStatus> checkStatus(String externalId) async =>
      DeliveryStatus.unknown;

  @override
  Future<bool> validateCredentials(Map<String, dynamic> credentials) async {
    try {
      await initialize(credentials);
      return true;
    } catch (_) {
      return false;
    }
  }
}
