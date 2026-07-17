import 'message_gateway.dart';
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
    'zenvia': () => ZenviaGateway(),
    'infobip': () => InfobipGateway(),
    'twilio': () => TwilioGateway(),
    'sinch': () => SinchGateway(),
    'totalvoice': () => TotalVoiceGateway(),
    'custom_webhook': () => CustomWebhookGateway(),
  };

  static final Map<String, ProviderMeta> metadata = {
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
      label: 'TotalVoice / Zenvia Voice',
      description: 'SMS nacional. Muito utilizado em automações brasileiras.',
      channels: [MessageChannel.sms],
      credentialFields: [
        CredentialField(key: 'access_token', label: 'Access Token', secret: true),
      ],
    ),
    'custom_webhook': ProviderMeta(
      type: 'custom_webhook',
      label: 'Webhook Customizado',
      description: 'Integre qualquer provedor via HTTP. Configure URL, headers e payload.',
      channels: [MessageChannel.sms, MessageChannel.rcs, MessageChannel.whatsapp],
      credentialFields: [
        CredentialField(key: 'url', label: 'URL do Endpoint'),
        CredentialField(key: 'method', label: 'Método HTTP (POST ou GET)'),
        CredentialField(key: 'headers', label: 'Headers (JSON)', hint: '{"Authorization":"Bearer xxx"}'),
        CredentialField(key: 'payload_template', label: 'Template do Payload (JSON)', hint: '{"to":"{{to}}","body":"{{body}}"}'),
      ],
    ),
  };

  static MessageGateway build(String type) {
    final factory = _factories[type];
    if (factory == null) throw ArgumentError('Provedor desconhecido: $type');
    return factory();
  }

  static List<ProviderMeta> get allProviders => metadata.values.toList();
}

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
