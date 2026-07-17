import 'dart:async';

import 'package:flutter/services.dart';

import 'message_gateway.dart';

/// Gateway que envia SMS diretamente pelo chip SIM do dispositivo Android.
///
/// • Completamente gratuito — usa o plano do usuário, sem API externa.
/// • Não requer cadastro em nenhum serviço.
/// • Suporta mensagens longas (multipart automático via SmsManager).
/// • Requer permissão SEND_SMS concedida pelo usuário.
class NativeSmsGateway implements MessageGateway {
  static const _channel = MethodChannel('br.com.disparopro/native_sms');

  @override
  String get providerType => 'native_sms';

  @override
  List<MessageChannel> get supportedChannels => [MessageChannel.sms];

  @override
  Future<void> initialize(Map<String, dynamic> credentials) async {
    // Sem credenciais necessárias — verifica apenas a permissão.
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      await _requestPermission();
    }
  }

  @override
  Future<GatewayResult> sendMessage({
    required String to,
    required String body,
    required MessageChannel channel,
    String? mediaUrl,
    Map<String, dynamic>? extra,
  }) async {
    if (channel != MessageChannel.sms) {
      return GatewayResult.err('NativeSmsGateway suporta apenas SMS.');
    }
    try {
      final success = await _channel.invokeMethod<bool>('sendSms', {
        'to': to,
        'body': body,
      });
      if (success == true) {
        return GatewayResult.ok(
          'native_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      return GatewayResult.err('SmsManager retornou false.');
    } on PlatformException catch (e) {
      final msg = e.code == 'PERMISSION_DENIED'
          ? 'Permissão SEND_SMS negada. Conceda a permissão nas configurações.'
          : 'Erro nativo: ${e.message}';
      return GatewayResult.err(msg);
    } catch (e) {
      return GatewayResult.err('Erro inesperado: $e');
    }
  }

  @override
  Future<List<GatewayResult>> sendBatch({
    required List<String> numbers,
    required String body,
    required MessageChannel channel,
    String? mediaUrl,
    int delayMs = 500,
  }) async {
    final results = <GatewayResult>[];
    for (final number in numbers) {
      final r = await sendMessage(to: number, body: body, channel: channel);
      results.add(r);
      if (delayMs > 0 && number != numbers.last) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    return results;
  }

  @override
  Future<DeliveryStatus> checkStatus(String externalId) async {
    // SmsManager não expõe status de entrega de forma síncrona.
    return DeliveryStatus.sent;
  }

  @override
  Future<bool> validateCredentials(Map<String, dynamic> credentials) async {
    return await _checkPermission();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<bool> _checkPermission() async {
    try {
      return await _channel.invokeMethod<bool>('checkPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _requestPermission() async {
    try {
      await _channel.invokeMethod<void>('requestPermission');
    } on PlatformException {
      // Permissão será solicitada quando tentar enviar.
    }
  }
}
