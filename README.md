# Disparo Pro

Plataforma nativa de disparo multi-canal — SMS, RCS e WhatsApp — para Android e iOS.  
100% gratuito, sem assinatura. Você paga apenas o custo por mensagem do provedor escolhido.

---

## ✦ Funcionalidades

| Feature | Status |
|---|---|
| Disparo SMS | ✅ |
| Disparo RCS | ✅ |
| Disparo WhatsApp Business | ✅ |
| Importação de contatos via CSV | ✅ |
| Grupos de contatos | ✅ |
| Templates com variáveis dinâmicas | ✅ |
| Agendamento de campanhas | ✅ |
| Controle de velocidade (lote + intervalo) | ✅ |
| Relatórios de entrega por canal | ✅ |
| Disparo em background (WorkManager) | ✅ |
| Notificações de progresso | ✅ |
| Multi-provedor | ✅ |

---

## 📡 Provedores suportados

| Provedor | SMS | RCS | WhatsApp |
|---|:---:|:---:|:---:|
| **Zenvia** | ✅ | ✅ | ✅ |
| **Infobip** | ✅ | ✅ | ✅ |
| **Twilio** | ✅ | — | ✅ |
| **Sinch** | ✅ | ✅ | — |
| **TotalVoice / Zenvia Voice** | ✅ | — | — |
| **Webhook customizado** | ✅ | ✅ | ✅ |

---

## 🏗 Arquitetura

```
lib/
├── core/
│   ├── database/          # Drift (SQLite) — contacts, campaigns, logs, providers
│   ├── gateway/           # Abstração + implementações de provedores
│   ├── background/        # WorkManager — disparo em background
│   ├── notifications/     # flutter_local_notifications
│   ├── router/            # go_router
│   ├── shell/             # Bottom nav shell
│   └── theme/             # Material 3, light + dark
├── features/
│   ├── dashboard/         # Stats + ações rápidas
│   ├── contacts/          # Lista, grupos, importação CSV
│   ├── campaigns/         # CRUD + monitor de progresso
│   ├── templates/         # Templates reutilizáveis com variáveis
│   ├── providers/         # Configuração de credenciais por provedor
│   ├── reports/           # Gráficos e taxas de entrega
│   └── settings/          # Config geral + export de dados
```

---

## 🚀 Configuração inicial

### Pré-requisitos

- Flutter SDK ≥ 3.22 (`flutter --version`)
- Android SDK (Android Studio ou CLI)
- Java 17

### Clonando e rodando

```bash
git clone https://github.com/<SEU_USUARIO>/disparo-pro.git
cd disparo-pro
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run                          # conecte um dispositivo Android ou use emulador
```

### Build de produção

```bash
# APK para distribuição direta
flutter build apk --release

# AAB para Google Play
flutter build appbundle --release
```

---

## 🔐 Releases automáticos (GitHub Actions)

### Android — todo push com tag `v*.*.*` gera release automático

```bash
git tag v1.0.0
git push origin v1.0.0
```

O workflow `.github/workflows/build_android.yml`:
1. Instala Flutter
2. Roda code generation (`build_runner`)
3. Compila APK + AAB release com keystore assinado
4. Cria GitHub Release com os artefatos

### Segredos necessários no repositório (Settings → Secrets)

| Secret | Descrição |
|---|---|
| `KEYSTORE_BASE64` | Keystore Android em base64 (`base64 upload-keystore.jks`) |
| `KEYSTORE_PASSWORD` | Senha do keystore |
| `KEY_ALIAS` | Alias da chave |
| `KEY_PASSWORD` | Senha da chave |

### iOS (opcional — requer runner macOS)

Adicione também:
- `IOS_CERTIFICATE_BASE64`
- `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `IOS_KEYCHAIN_PASSWORD`

---

## ⚙️ Adicionando um novo provedor

1. Implemente `MessageGateway` em `lib/core/gateway/`
2. Registre o factory e o `ProviderMeta` em `GatewayRegistry`
3. O formulário de provedores no app detecta automaticamente os campos de credenciais

---

## 📋 Permissões Android

| Permissão | Motivo |
|---|---|
| `INTERNET` | Chamadas às APIs dos provedores |
| `POST_NOTIFICATIONS` | Notificações de progresso (Android 13+) |
| `RECEIVE_BOOT_COMPLETED` | Reativar campanhas agendadas após reinício |
| `WAKE_LOCK` + `FOREGROUND_SERVICE` | WorkManager para disparo em background |
| `READ_EXTERNAL_STORAGE` / `READ_MEDIA_*` | Importação de CSV |

---

## 📄 Licença

MIT — use, modifique e distribua livremente.
