/// Abstract interface que todos os provedores devem implementar.
/// Cada gateway cuida de um canal/provedor específico.
abstract class MessageGateway {
  /// Identificador do tipo do provedor
  String get providerType;

  /// Canais suportados por este gateway
  List<MessageChannel> get supportedChannels;

  /// Inicializa o gateway com as credenciais configuradas
  Future<void> initialize(Map<String, dynamic> credentials);

  /// Envia uma mensagem para um número
  Future<GatewayResult> sendMessage({
    required String to,
    required String body,
    required MessageChannel channel,
    String? mediaUrl,
    Map<String, dynamic>? extra,
  });

  /// Envia em lote (com controle de rate-limit)
  Future<List<GatewayResult>> sendBatch({
    required List<String> numbers,
    required String body,
    required MessageChannel channel,
    String? mediaUrl,
    int delayMs = 200,
  });

  /// Verifica status de entrega pelo ID externo
  Future<DeliveryStatus> checkStatus(String externalId);

  /// Valida se as credenciais estão corretas
  Future<bool> validateCredentials(Map<String, dynamic> credentials);
}

enum MessageChannel { sms, rcs, whatsapp }

enum DeliveryStatus { pending, sent, delivered, read, failed, unknown }

class GatewayResult {
  final bool success;
  final String? externalId;
  final String? errorMessage;
  final Map<String, dynamic>? rawResponse;

  const GatewayResult({
    required this.success,
    this.externalId,
    this.errorMessage,
    this.rawResponse,
  });

  factory GatewayResult.ok(String externalId, [Map<String, dynamic>? raw]) =>
      GatewayResult(success: true, externalId: externalId, rawResponse: raw);

  factory GatewayResult.err(String message, [Map<String, dynamic>? raw]) =>
      GatewayResult(success: false, errorMessage: message, rawResponse: raw);
}
