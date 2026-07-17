# Disparo Pro (DyanX)

Plataforma nativa Flutter de disparo multi-canal — SMS, RCS e WhatsApp — para Android e iOS. 100% gratuito, sem assinatura. O usuário paga apenas o custo por mensagem do provedor escolhido.

## Run & Operate

- `flutter pub get` — instala dependências Dart/Flutter
- `dart run build_runner build --delete-conflicting-outputs` — gera código (Drift, Freezed, Riverpod)
- `flutter run` — roda no dispositivo/emulador conectado
- `flutter build apk --release` — gera APK de produção
- `flutter build appbundle --release` — gera AAB para Google Play

## Stack

- Flutter ≥ 3.22 / Dart ≥ 3.3
- State management: Riverpod 2 + riverpod_generator
- Navegação: go_router
- Banco local: Drift (SQLite) + drift_dev
- HTTP: Dio
- Background: WorkManager
- Notificações: flutter_local_notifications
- Charts: fl_chart
- Modelos: Freezed + json_serializable

## Where things live

- `lib/core/` — infraestrutura: banco, gateways de provedor, router, tema, background worker
- `lib/features/` — funcionalidades: dashboard, contacts, campaigns, templates, providers, reports, settings
- `android/` — código nativo Android (NativeSmsPlugin.kt para SMS nativo)
- `assets/` — imagens, ícones, animações Lottie
- `.github/workflows/` — CI/CD: build automático de APK/AAB no push com tag `v*`

## Architecture decisions

- Feature-first layout sob `lib/features/`, cada feature com `data/`, `presentation/` e `providers/`
- Abstração de gateway (`message_gateway.dart`) permite trocar/adicionar provedores sem mudar lógica de campanha
- Drift (SQLite local) para dados offline-first: campanhas, contatos, logs, templates, provedores
- WorkManager para disparo em background mesmo com app fechado

## Product

App mobile de disparo de mensagens em massa. Permite criar campanhas com templates dinâmicos, importar contatos via CSV/VCF, configurar múltiplos provedores (Zenvia, Infobip, Twilio, Sinch, TotalVoice, Webhook custom), agendar disparos e acompanhar relatórios de entrega.

## Provedores suportados

| Provedor | SMS | RCS | WhatsApp |
|---|:---:|:---:|:---:|
| Zenvia | ✅ | ✅ | ✅ |
| Infobip | ✅ | ✅ | ✅ |
| Twilio | ✅ | — | ✅ |
| Sinch | ✅ | ✅ | — |
| TotalVoice | ✅ | — | — |
| Webhook customizado | ✅ | ✅ | ✅ |

## User preferences

_Populate as you build — explicit user instructions worth remembering across sessions._

## Gotchas

- Após qualquer mudança em arquivos `*.dart` com anotações geradas (Drift, Freezed, Riverpod), rodar `dart run build_runner build --delete-conflicting-outputs` antes de compilar.
- O plugin `NativeSmsPlugin.kt` permite disparo via SMS nativo do Android (sem provedor externo).

## Pointers

- Repositório original: https://github.com/ViaXTrace/disparo-pro
- See the `pnpm-workspace` skill for workspace structure (monorepo Node.js coexistente)
