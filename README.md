# App Clubee - Sistema Multi-Cliente

Um aplicativo Flutter configurado para servir múltiplos clientes com diferentes temas, configurações e package names.

## 🏢 Clientes Configurados

- **Guará** (`com.guaraapp` / `com.lsdevelopers.guaraapp`)
- **Vale das Minas** (`com.valedasminas` / `com.lsdevelopers.valedasminas`)

## 🚀 Início Rápido

### ⚙️ Entendendo a Configuração Dual

O App Clubee usa **dois níveis de configuração**:

1. **Configuração Nativa** (Android/iOS) - Define package names, bundle IDs, Firebase
   - Executado via: `./scripts/configure_client.sh [cliente]`
   - Altera: AndroidManifest.xml, build.gradle.kts, Info.plist, etc.

2. **Configuração Flutter** (Tema, cores, logo) - Define qual cliente o app exibe
   - Executado via: `--dart-define=CLIENT_TYPE=[cliente]`
   - Altera: Tema, cores primárias, logo, nome do app no Flutter

**⚠️ IMPORTANTE:** Ambos precisam ser configurados para o mesmo cliente!

### Desenvolvimento

```bash
# 1. Configurar infraestrutura nativa para Vale das Minas
./scripts/configure_client.sh vale_das_minas

# 2. Limpar projeto
flutter clean && flutter pub get

# 3. Executar com o cliente Vale das Minas
flutter run --dart-define=CLIENT_TYPE=vale_das_minas
```

```bash
# Para Guará (valor padrão se não especificar --dart-define)
./scripts/configure_client.sh guara
flutter clean && flutter pub get
flutter run --dart-define=CLIENT_TYPE=guara
# ou simplesmente
flutter run
```

### Build para Produção
```bash
# Android - Guará
./scripts/build_android.sh guara release

# Android - Vale das Minas  
./scripts/build_android.sh vale_das_minas release

# iOS - Guará (apenas macOS)
./scripts/build_ios.sh guara release

# iOS - Vale das Minas (apenas macOS)
./scripts/build_ios.sh vale_das_minas release
```

## ➕ Adicionar Novo Cliente

```bash
# Método interativo (recomendado)
./scripts/add_new_client.sh

# Método rápido
./scripts/quick_add_client.sh "Nome Cliente" "#COR1" "#COR2" "android.package" "ios.bundle"
```

## 📁 Estrutura do Projeto

```
lib/
├── config/           # Configurações por cliente
├── services/         # Serviços (ClientService)
├── widgets/          # Widgets reutilizáveis
└── main.dart        # Ponto de entrada

assets/
└── images/          # Assets organizados por cliente
    ├── common/      # Assets compartilhados
    ├── guara/       # Assets do Guará
    └── vale_das_minas/ # Assets do Vale das Minas

scripts/             # Scripts de automação
├── add_new_client.sh    # Adicionar cliente
├── build_android.sh     # Build Android
├── build_ios.sh         # Build iOS
└── quick_add_client.sh  # Adição rápida

docs/               # Documentação completa
```

## 📚 Documentação

Consulte a pasta [`docs/`](./docs/) para documentação completa:

- [📋 Índice da Documentação](./docs/INDEX.md)
- [🔧 Scripts de Clientes](./docs/SCRIPTS_CLIENTES.md)
- [📱 Instruções de Build](./docs/BUILD_INSTRUCTIONS.md)
- [⚙️ Setup Multi-Cliente](./docs/MULTI_CLIENT_SETUP.md)

## 🛠️ Requisitos

- Flutter SDK
- Dart SDK
- Android Studio (para builds Android)
- Xcode (para builds iOS - apenas macOS)

## 📄 Licença

Este projeto foi desenvolvido para uso interno da LS Developers.