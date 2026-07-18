import 'dart:convert';
import 'package:dio/dio.dart';
import 'message_gateway.dart';

/// Twilio — SMS e WhatsApp Business API.
/// Docs: https://www.twilio.com/docs/sms/api
class TwilioGateway implements MessageGateway {
  late Dio _dio;
  late String _accountSid;
  late String _from;

  @override
  String get providerType => 'twilio';

  @override
  List<MessageChannel> get supportedChannels =>
      [MessageChannel.sms, MessageChannel.whatsapp];

  @override
  Future<void> initialize(Map<String, dynamic> credentials) async {
    _accountSid = credentials['account_sid'] as String;
    final authToken = credentials['auth_token'] as String;
    _from = credentials['from'] as String;
    final basic = base64Encode(utf8.encode('$_accountSid:$authToken'));
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.twilio.com/2010-04-01',
      headers: {'Authorization': 'Basic $basic'},
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
      final toFormatted =
          channel == MessageChannel.whatsapp ? 'whatsapp:$to' : to;
      final fromFormatted =
          channel == MessageChannel.whatsapp ? 'whatsapp:$_from' : _from;
      final data = {
        'To': toFormatted,
        'From': fromFormatted,
        'Body': body,
        if (mediaUrl != null) 'MediaUrl': mediaUrl,
      };
      final resp = await _dio.post(
        '/Accounts/$_accountSid/Messages.json',
        data: FormData.fromMap(data),
      );
      final sid = resp.data['sid'] as String?;
      return GatewayResult.ok(sid ?? '', resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return GatewayResult.err(
        e.response?.data?['message'] as String? ?? e.message ?? 'Erro',
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
    for (final n in numbers) {
      results.add(await sendMessage(to: n, body: body, channel: channel, mediaUrl: mediaUrl));
      if (delayMs > 0) await Future.delayed(Duration(milliseconds: delayMs));
    }
    return results;
  }

  @override
  Future<DeliveryStatus> checkStatus(String externalId) async {
    try {
      final resp = await _dio.get('/Accounts/$_accountSid/Messages/$externalId.json');
      return _mapStatus(resp.data['status'] as String? ?? '');
    } catch (_) {
      return DeliveryStatus.unknown;
    }
  }

  @override
  Future<bool> validateCredentials(Map<String, dynamic> credentials) async {
    try {
      await initialize(credentials);
      await _dio.get('/Accounts/$_accountSid.json');
      return true;
    } catch (_) {
      return false;
    }
  }

  DeliveryStatus _mapStatus(String s) => switch (s) {
        'delivered' => DeliveryStatus.delivered,
        'read' => DeliveryStatus.read,
        'sent' || 'queued' || 'accepted' => DeliveryStatus.sent,
        'failed' || 'undelivered' => DeliveryStatus.failed,
        _ => DeliveryStatus.pending,
      };
}
