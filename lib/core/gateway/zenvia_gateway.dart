import 'package:dio/dio.dart';
import 'message_gateway.dart';

/// Zenvia — maior provedor brasileiro, suporta SMS, RCS e WhatsApp.
/// Docs: https://zenvia.com/api
class ZenviaGateway implements MessageGateway {
  late Dio _dio;
  late String _token;
  late String _from;

  @override
  String get providerType => 'zenvia';

  @override
  List<MessageChannel> get supportedChannels =>
      [MessageChannel.sms, MessageChannel.rcs, MessageChannel.whatsapp];

  @override
  Future<void> initialize(Map<String, dynamic> credentials) async {
    _token = credentials['token'] as String;
    _from = credentials['from'] as String;
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.zenvia.com/v2',
      headers: {'X-API-TOKEN': _token, 'Content-Type': 'application/json'},
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
    final channelPath = _channelPath(channel);
    try {
      final payload = {
        'from': _from,
        'to': to,
        'contents': [
          if (mediaUrl != null) {'type': 'file', 'fileUrl': mediaUrl},
          {'type': 'text', 'text': body},
        ],
      };
      final resp = await _dio.post('/channels/$channelPath/messages', data: payload);
      final id = resp.data['id'] as String?;
      return GatewayResult.ok(id ?? '', resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return GatewayResult.err(
        e.response?.data.toString() ?? e.message ?? 'Erro desconhecido',
        e.response?.data as Map<String, dynamic>?,
      );
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
    for (final number in numbers) {
      final r = await sendMessage(to: number, body: body, channel: channel, mediaUrl: mediaUrl);
      results.add(r);
      if (delayMs > 0) await Future.delayed(Duration(milliseconds: delayMs));
    }
    return results;
  }

  @override
  Future<DeliveryStatus> checkStatus(String externalId) async {
    try {
      final resp = await _dio.get('/messages/$externalId');
      final status = resp.data['status'] as String? ?? '';
      return _mapStatus(status);
    } catch (_) {
      return DeliveryStatus.unknown;
    }
  }

  @override
  Future<bool> validateCredentials(Map<String, dynamic> credentials) async {
    try {
      await initialize(credentials);
      await _dio.get('/channels');
      return true;
    } catch (_) {
      return false;
    }
  }

  String _channelPath(MessageChannel ch) => switch (ch) {
        MessageChannel.sms => 'sms',
        MessageChannel.rcs => 'rcs',
        MessageChannel.whatsapp => 'whatsapp',
      };

  DeliveryStatus _mapStatus(String s) => switch (s.toLowerCase()) {
        'delivered' => DeliveryStatus.delivered,
        'read' => DeliveryStatus.read,
        'sent' => DeliveryStatus.sent,
        'failed' || 'rejected' => DeliveryStatus.failed,
        _ => DeliveryStatus.pending,
      };
}
