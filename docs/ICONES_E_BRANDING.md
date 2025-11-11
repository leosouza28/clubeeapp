# Sistema de Ícones e Branding - App Clubee

Sistema completo para configurar ícones e nomes específicos por cliente.

## 📱 Configuração de Nomes

### Nomes por Cliente

#### Guará Park
- **Nome de Exibição:** "Guará Park"
- **Nome Interno:** "guara_park"
- **Android Label:** "Guará Park"
- **iOS Display Name:** "Guará Park"

#### Vale das Minas
- **Nome de Exibição:** "Vale das Minas"
- **Nome Interno:** "vale_das_minas"
- **Android Label:** "Vale das Minas"
- **iOS Display Name:** "Vale das Minas"

## 🎨 Sistema de Ícones

### Estrutura de Pastas
```
assets/icons/
├── guara/
│   ├── icon.png (1024x1024)
│   ├── adaptive_icon.png (432x432)
│   └── README.md
└── valedasminas/
    ├── icon.png (1024x1024)
    ├── adaptive_icon.png (432x432)
    └── README.md
```

### Especificações dos Ícones

#### Ícone Principal (icon.png)
- **Tamanho:** 1024x1024 pixels
- **Formato:** PNG com fundo transparente
- **Uso:** Ícone base para todas as plataformas

#### Ícone Adaptativo Android (adaptive_icon.png)
- **Tamanho:** 432x432 pixels
- **Formato:** PNG com fundo transparente
- **Uso:** Primeiro plano do ícone adaptativo Android
- **Área segura:** 300x300 pixels centralizados

### Cores por Cliente

#### Guará Park
- **Cor Principal:** #1976D2 (azul)
- **Cor Secundária:** #FF9800 (laranja)
- **Fundo Adaptativo:** #1976D2

#### Vale das Minas
- **Cor Principal:** #4CAF50 (verde)
- **Cor Secundária:** #FFC107 (amarelo)
- **Fundo Adaptativo:** #4CAF50

## 🚀 Como Usar

### 1. Preparar Ícones

Coloque seus ícones nas pastas corretas:
```bash
# Para Guará
assets/icons/guara/icon.png
assets/icons/guara/adaptive_icon.png

# Para Vale das Minas
assets/icons/valedasminas/icon.png
assets/icons/valedasminas/adaptive_icon.png
```

### 2. Gerar Ícones para um Cliente

```bash
# Gerar ícones específicos
./scripts/generate_icons.sh guara
./scripts/generate_icons.sh vale_das_minas
```

### 3. Configurar Aplicativo Completo

```bash
# Configurar tudo (ícones + nomes + Firebase)
./scripts/prepare_build.sh guara
./scripts/prepare_build.sh vale_das_minas
```

### 4. Build do Aplicativo

```bash
# Depois da configuração
flutter clean && flutter pub get
flutter build ios
flutter build android
```

## 🔧 Scripts Disponíveis

### `generate_icons.sh`
Gera ícones específicos para um cliente usando flutter_launcher_icons.

**Uso:**
```bash
./scripts/generate_icons.sh [guara|vale_das_minas]
```

**O que faz:**
- Usa configuração específica do cliente
- Gera ícones para Android (todas as densidades)
- Gera ícones para iOS (App Store + dispositivos)
- Cria ícones adaptativos para Android

### `prepare_build.sh` (Atualizado)
Prepara build completo incluindo ícones automáticos.

**Processo:**
1. Verifica se existem ícones específicos
2. Gera ícones automaticamente (se encontrados)
3. Configura nomes e identidades
4. Configura Firebase
5. Executa flutter clean e pub get

### `build_client.sh` (Atualizado)
Configura nomes de exibição e identidades.

**Configurações aplicadas:**
- Package names Android/iOS
- Nomes de exibição por cliente
- Labels internos
- Configurações Firebase

## 📋 Configurações por Plataforma

### Android
- **AndroidManifest.xml:** android:label alterado
- **Ícones:** Gerados em res/mipmap-*/ 
- **Ícone adaptativo:** Suporte completo com foreground/background

### iOS
- **Info.plist:** CFBundleDisplayName e CFBundleName alterados
- **Ícones:** Gerados em Assets.xcassets/AppIcon.appiconset/
- **App Store:** Todos os tamanhos necessários incluídos

## 🎯 Fluxo Recomendado

### Setup Inicial
1. **Criar ícones:** Design personalizado para cada cliente
2. **Colocar nos locais corretos:** assets/icons/[cliente]/
3. **Testar geração:** `./scripts/generate_icons.sh [cliente]`

### Build de Produção
1. **Preparar:** `./scripts/prepare_build.sh [cliente]`
2. **Build:** `flutter build [platform]`
3. **Limpar:** `./scripts/clean_firebase.sh`

### Desenvolvimento
1. **Configurar cliente:** `./scripts/build_client.sh [cliente]`
2. **Desenvolver:** `flutter run`
3. **Trocar cliente:** Repetir processo

## ⚠️ Importantes

### Qualidade dos Ícones
- Use imagens vetoriais ou alta resolução
- Teste em diferentes tamanhos e fundos
- Mantenha consistência visual entre plataformas

### Cores e Branding
- Respeite as diretrizes de cada cliente
- Use cores contrastantes para legibilidade
- Teste em modo claro e escuro

### Performance
- Ícones são otimizados automaticamente
- Formatos apropriados por plataforma
- Tamanhos corretos para cada densidade

## 🐛 Troubleshooting

### Erro: "icon.png não encontrado"
1. Verifique se o arquivo existe no local correto
2. Confirme o nome exato do arquivo
3. Verifique permissões de leitura

### Ícones não aparecem no app
1. Execute flutter clean
2. Rebuild completo do projeto
3. Verifique se flutter_launcher_icons executou com sucesso

### Diferenças entre plataformas
1. Ícones iOS e Android têm especificações diferentes
2. Use adaptive_icon.png para melhor resultado no Android
3. Teste em dispositivos reais