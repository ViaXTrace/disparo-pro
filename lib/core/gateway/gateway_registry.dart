import 'message_gateway.dart';
import 'native_sms_gateway.dart';
import 'zenvia_gateway.dart';
import 'infobip_gateway.dart';
import 'twilio_gateway.dart';
import 'sinch_gateway.dart';
import 'totalvoice_gateway.dart';
import 'custom_webhook_gateway.dart';

/// Registro central de todos os gateways disponíveis.
/// Para adicionar um novo provedor: implemente MessageGateway e registre aqui.
class GatewayRegistry {
  GatewayRegistry._();

  static final Map<String, MessageGateway Function()> _factories = {
    'native_sms': () => NativeSmsGateway(),
    'zenvia': () => ZenviaGateway(),
    'infobip': () => InfobipGateway(),
    'twilio': () => TwilioGateway(),
    'sinch': () => SinchGateway(),
    'totalvoice': () => TotalVoiceGateway(),
    'custom_webhook': () => CustomWebhookGateway(),
  };

  static final Map<String, ProviderMeta> metadata = {
    'native_sms': ProviderMeta(
      type: 'native_sms',
      label: 'SMS Nativo (Gratuito)',
      description:
          'Envia SMS diretamente pelo chip SIM do dispositivo. Completamente '
          'gratuito — usa o plano de dados/SMS do usuário. Não requer conta '
          'em nenhum serviço externo.',
      channels: [MessageChannel.sms],
      credentialFields: const [],
    ),
    'zenvia': ProviderMeta(
      type: 'zenvia',
      label: 'Zenvia',
      description: 'Maior provedor de CPaaS do Brasil. SMS, RCS e WhatsApp.',
      channels: [MessageChannel.sms, MessageChannel.rcs, MessageChannel.whatsapp],
      credentialFields: [
        CredentialField(key: 'token', label: 'API Token', secret: true),
        CredentialField(key: 'from', label: 'Número Remetente (ex: 5511999990000)'),
      ],
    ),
    'infobip': ProviderMeta(
      type: 'infobip',
      label: 'Infobip',
      description: 'Plataforma global com escritório no Brasil. SMS, RCS e WhatsApp.',
      channels: [MessageChannel.sms, MessageChannel.rcs, MessageChannel.whatsapp],
      credentialFields: [
        CredentialField(key: 'api_key', label: 'API Key', secret: true),
        CredentialField(key: 'base_url', label: 'Base URL (ex: xxxxx.api.infobip.com)'),
        CredentialField(key: 'from', label: 'Número Remetente'),
      ],
    ),
    'twilio': ProviderMeta(
      type: 'twilio',
      label: 'Twilio',
      description: 'Referência global. SMS e WhatsApp Business API.',
      channels: [MessageChannel.sms, MessageChannel.whatsapp],
      credentialFields: [
        CredentialField(key: 'account_sid', label: 'Account SID'),
        CredentialField(key: 'auth_token', label: 'Auth Token', secret: true),
        CredentialField(key: 'from', label: 'Número Remetente ou SID de número'),
      ],
    ),
    'sinch': ProviderMeta(
      type: 'sinch',
      label: 'Sinch',
      description: 'SMS e RCS com cobertura nacional via operadoras brasileiras.',
      channels: [MessageChannel.sms, MessageChannel.rcs],
      credentialFields: [
        CredentialField(key: 'service_plan_id', label: 'Service Plan ID'),
        CredentialField(key: 'api_token', label: 'API Token', secret: true),
        CredentialField(key: 'from', label: 'Número Remetente'),
      ],
    ),
    'totalvoice': ProviderMeta(
      type: 'totalvoice',
      label: 'TotalVoice',
      description: 'Provedor brasileiro focado em SMS e voz.',
      channels: [MessageChannel.sms],
      credentialFields: [
        CredentialField(key: 'access_token', label: 'Access Token', secret: true),
        CredentialField(key: 'from', label: 'Número Remetente'),
      ],
    ),
    'custom_webhook': ProviderMeta(
      type: 'custom_webhook',
      label: 'Webhook Personalizado',
      description: 'Integre qualquer API via template HTTP customizável.',
      channels: [MessageChannel.sms, MessageChannel.rcs, MessageChannel.whatsapp],
      credentialFields: [
        CredentialField(key: 'url', label: 'URL do Webhook'),
        CredentialField(key: 'method', label: 'Método HTTP (GET/POST)'),
        CredentialField(
            key: 'body_template',
            label: 'Template do body (use {{to}} e {{body}})'),
        CredentialField(key: 'headers', label: 'Headers JSON (opcional)'),
      ],
    ),
  };

  /// Lista de todos os provedores registrados (usada nas telas de UI).
  static List<ProviderMeta> get allProviders => metadata.values.toList();

  /// Lista de tipos de provedor disponíveis.
  static List<String> get registeredTypes => _factories.keys.toList();

  /// Constrói (instancia) um gateway pelo tipo.
  /// Lança [ArgumentError] se o tipo não estiver registrado.
  static MessageGateway build(String type) {
    final factory = _factories[type];
    if (factory == null) throw ArgumentError('Gateway não encontrado: $type');
    return factory();
  }

  /// Retorna os metadados de um tipo de provedor.
  static ProviderMeta? getMeta(String type) => metadata[type];
}

// ── Data classes ─────────────────────────────────────────────────────────────

class ProviderMeta {
  final String type;
  final String label;
  final String description;
  final List<MessageChannel> channels;
  final List<CredentialField> credentialFields;

  const ProviderMeta({
    required this.type,
    required this.label,
    required this.description,
    required this.channels,
    required this.credentialFields,
  });
}

class CredentialField {
  final String key;
  final String label;
  final bool secret;
  final String? hint;

  const CredentialField({
    required this.key,
    required this.label,
    this.secret = false,
    this.hint,
  });
}
