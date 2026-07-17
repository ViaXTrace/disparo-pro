import 'package:dio/dio.dart';
import 'message_gateway.dart';

/// Sinch — SMS e RCS com boa cobertura no Brasil via parceria com operadoras.
/// Docs: https://developers.sinch.com/docs/sms/api-reference
class SinchGateway implements MessageGateway {
  late Dio _dio;
  late Dio _rcsClient;
  late String _servicePlanId;
  late String _from;

  @override
  String get providerType => 'sinch';

  @override
  List<MessageChannel> get supportedChannels =>
      [MessageChannel.sms, MessageChannel.rcs];

  @override
  Future<void> initialize(Map<String, dynamic> credentials) async {
    _servicePlanId = credentials['service_plan_id'] as String;
    final token = credentials['api_token'] as String;
    _from = credentials['from'] as String;

    _dio = Dio(BaseOptions(
      baseUrl: 'https://us.sms.api.sinch.com/xms/v1/$_servicePlanId',
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    ));

    final projectId = credentials['project_id'] as String? ?? '';
    final keyId = credentials['key_id'] as String? ?? '';
    final keySecret = credentials['key_secret'] as String? ?? '';
    _rcsClient = Dio(BaseOptions(
      baseUrl: 'https://rcs.api.sinch.com/v1/projects/$projectId',
      headers: {'Authorization': 'Bearer $keyId:$keySecret'},
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
      if (channel == MessageChannel.sms) {
        final resp = await _dio.post('/batches', data: {
          'from': _from,
          'to': [to],
          'body': body,
        });
        return GatewayResult.ok(
            resp.data['id'] as String? ?? '', resp.data as Map<String, dynamic>);
      } else {
        // RCS via Sinch Conversation API
        final resp = await _rcsClient.post('/messages', data: {
          'message': {'text': body},
          'recipient': {'identified_by': {'channel_identities': [{'channel': 'RCS', 'identity': to}]}},
        });
        return GatewayResult.ok(
            resp.data['message_id'] as String? ?? '', resp.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      return GatewayResult.err(e.response?.data.toString() ?? e.message ?? 'Erro');
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
    if (channel == MessageChannel.sms && numbers.length > 1) {
      // Sinch SMS supports multi-recipient in one call
      try {
        final resp = await _dio.post('/batches', data: {
          'from': _from,
          'to': numbers,
          'body': body,
        });
        final id = resp.data['id'] as String? ?? '';
        return numbers.map((_) => GatewayResult.ok(id)).toList();
      } on DioException catch (e) {
        final err = GatewayResult.err(e.message ?? 'Erro em lote');
        return numbers.map((_) => err).toList();
      }
    }
    final results = <GatewayResult>[];
    for (final n in numbers) {
      results.add(await sendMessage(to: n, body: body, channel: channel, mediaUrl: mediaUrl));
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
      await _dio.get('/batches?page_size=1');
      return true;
    } catch (_) {
      return false;
    }
  }
}
