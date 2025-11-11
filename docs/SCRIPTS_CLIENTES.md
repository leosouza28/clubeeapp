# 🔧 Scripts para Gerenciamento de Clientes

## 📋 Scripts Disponíveis

### 1. Adicionar Novo Cliente (Interativo)
```bash
./scripts/add_new_client.sh
```
**O que faz:**
- 🗣️ Interface interativa para coletar informações
- ✨ Gera automaticamente IDs e nomes de variáveis
- 🎨 Configura temas personalizados
- 📱 Define package names para Android e iOS
- 🏗️ Cria estrutura completa de assets
- 🔄 Atualiza todos os scripts de build
- ✅ Verifica se o código compila

**Informações solicitadas:**
- Nome do cliente
- Cores primária e secundária
- URL da API
- Package name Android
- Bundle ID iOS
- Email de suporte
- Número máximo de usuários
- Habilitar/desabilitar features

### 2. Adicionar Cliente Rápido (Linha de Comando)
```bash
./scripts/quick_add_client.sh "Nome Cliente" "#FF5722" "#FFC107" "com.cliente" "com.lsdevelopers.cliente"
```
**Exemplo:**
```bash
./scripts/quick_add_client.sh "Clube ABC" "#E91E63" "#FF5722" "com.clubeabc" "com.lsdevelopers.clubeabc"
```

### 3. Remover Cliente
```bash
./scripts/remove_client.sh [client_id]
```
**O que faz:**
- 🗑️ Remove cliente do enum e configurações
- 📁 Remove pasta de assets
- ♻️ Restaura backups quando possível
- 🧹 Limpa referências do pubspec.yaml

## 🎯 Exemplos Práticos

### Adicionar "Clube Juventus"
```bash
# Método interativo (recomendado)
./scripts/add_new_client.sh

# Método rápido
./scripts/quick_add_client.sh "Clube Juventus" "#000000" "#FFFFFF" "com.juventus" "com.lsdevelopers.juventus"
```

### Testar o novo cliente
```bash
# Executar em debug com o novo cliente
flutter run --dart-define=CLIENT_TYPE=clube_juventus

# Build para produção
./scripts/build_android.sh clube_juventus release
./scripts/build_ios.sh clube_juventus release
```

### Remover cliente
```bash
./scripts/remove_client.sh clube_juventus
```

## 🏗️ O que é criado automaticamente

### 1. Código Dart
- ✅ Enum `ClientType` atualizado
- ✅ Configuração em `ClientConfig`
- ✅ Tema personalizado
- ✅ Suporte no `ClientEnvironment`

### 2. Assets
- 📁 Pasta `assets/images/[client_id]/`
- 📝 README com instruções
- ⚙️ Configuração no `pubspec.yaml`

### 3. Scripts de Build
- 🤖 Android build script atualizado
- 🍎 iOS build script atualizado
- ⚙️ Configuração manual atualizada

### 4. Configurações Específicas
- 📱 Package name Android único
- 🍎 Bundle ID iOS único
- 🌐 URL de API personalizada
- 📧 Email de suporte
- ⚡ Configurações de features

## 🔄 Fluxo Completo

### Para adicionar um novo cliente:
1. **Execute o script:** `./scripts/add_new_client.sh`
2. **Preencha as informações** solicitadas
3. **Adicione o logo:** `assets/images/[client_id]/logo.png`
4. **Teste:** `flutter run --dart-define=CLIENT_TYPE=[client_id]`
5. **Build:** `./scripts/build_android.sh [client_id] release`

### Estrutura gerada:
```
lib/config/
├── client_type.dart          # ← Enum atualizado
├── client_config.dart        # ← Configuração adicionada
└── client_environment.dart   # ← Suporte adicionado

assets/images/
└── [client_id]/              # ← Nova pasta
    ├── README.md
    └── logo.png              # ← Adicionar manualmente

scripts/
├── build_android.sh          # ← Atualizado
├── build_ios.sh              # ← Atualizado
└── build_client.sh           # ← Atualizado
```

## 🛡️ Recursos de Segurança

- ✅ **Backups automáticos** dos arquivos modificados
- ✅ **Validação** de parâmetros de entrada
- ✅ **Verificação** se o código compila
- ✅ **Confirmação** antes de operações destrutivas
- ✅ **Logs detalhados** de cada operação

## 🚨 Troubleshooting

### Script não executa
```bash
chmod +x scripts/*.sh
```

### Erro de compilação após adicionar cliente
```bash
# Restaurar backups
cp lib/config/client_type.dart.backup lib/config/client_type.dart
cp lib/config/client_config.dart.backup lib/config/client_config.dart

# Limpar cache
flutter clean && flutter pub get
```

### Cliente não aparece no seletor
- Verifique se foi adicionado ao enum `ClientType`
- Execute `flutter clean && flutter pub get`
- Reinicie o app

## 💡 Dicas

1. **Use nomes simples** para clientes (evite caracteres especiais)
2. **Teste sempre** após adicionar um cliente
3. **Mantenha backups** antes de modificações importantes
4. **Use o método interativo** para maior controle
5. **Adicione logos** imediatamente após criar o cliente

## 🎉 Resultado Final

Após executar o script, você terá:
- ✅ Novo cliente totalmente funcional
- ✅ Scripts de build atualizados
- ✅ Estrutura de assets criada
- ✅ Configurações únicas de package/bundle
- ✅ Tema personalizado aplicado
- ✅ Pronto para desenvolvimento e produção!