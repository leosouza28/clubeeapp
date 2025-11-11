# Sistema Multi-Cliente - App Clubee

Este projeto foi configurado para servir múltiplos clientes com diferentes configurações, temas e assets.

## Clientes Atualmente Configurados

1. **Guará** 
   - ID: `guara`
   - Cor primária: Azul (#1976D2)
   - Cor secundária: Laranja (#FF9800)

2. **Vale das Minas**
   - ID: `vale_das_minas`
   - Cor primária: Verde (#4CAF50)
   - Cor secundária: Amarelo (#FFC107)

## Estrutura do Projeto

### Configuração de Clientes
- `lib/config/client_type.dart` - Enum com os tipos de cliente
- `lib/config/client_config.dart` - Configurações específicas de cada cliente
- `lib/services/client_service.dart` - Serviço para gerenciar cliente atual

### Assets por Cliente
```
assets/
├── images/
│   ├── common/          # Assets compartilhados
│   ├── guara/          # Assets específicos do Guará
│   └── vale_das_minas/ # Assets específicos do Vale das Minas
```

### Widgets
- `lib/widgets/client_selector.dart` - Seletor de cliente (apenas em debug)

## Como Usar

### 1. Alternar Cliente Durante Desenvolvimento

Para alternar entre clientes durante o desenvolvimento, use dart-define:

```bash
# Executar com Guará
flutter run --dart-define=CLIENT_TYPE=guara

# Executar com Vale das Minas
flutter run --dart-define=CLIENT_TYPE=vale_das_minas
```

### 2. Configurar Cliente Padrão

No arquivo `main.dart`, altere a linha:
```dart
ClientService.instance.setClient(ClientType.guara); // ou ClientType.valeDasMinas
```

### 3. Acessar Configuração do Cliente Atual

```dart
final clientService = ClientService.instance;
final config = clientService.currentConfig;

// Usar configurações
Text(config.appName);
Container(color: config.theme.primaryColor);
Image.asset(config.logoPath);
```

### 4. Verificar Funcionalidades Específicas

```dart
// Verificar se uma feature está habilitada
if (clientService.isFeatureEnabled('enableFeatureX')) {
  // Mostrar funcionalidade específica
}

// Obter configuração customizada
String? supportEmail = clientService.getCustomSetting<String>('supportEmail');
int? maxUsers = clientService.getCustomSetting<int>('maxUsers');
```

## Adicionando Novos Clientes

### 1. Adicionar ao Enum
Em `client_type.dart`:
```dart
enum ClientType {
  guara,
  valeDasMinas,
  novoCliente; // Adicionar aqui
}
```

### 2. Configurar Cliente
Em `client_config.dart`, adicionar novo case no `factory ClientConfig.fromClientType()`:
```dart
case ClientType.novoCliente:
  return ClientConfig(
    clientType: clientType,
    appName: 'Clubee - Novo Cliente',
    logoPath: 'assets/images/novo_cliente/logo.png',
    theme: _createNovoClienteTheme(),
    primaryColor: '#YOUR_COLOR',
    secondaryColor: '#YOUR_SECONDARY_COLOR',
    apiBaseUrl: 'https://api.novocliente.clubee.com',
    customSettings: {
      'enableFeatureX': true,
      'maxUsers': 2000,
    },
  );
```

### 3. Criar Assets
Criar pasta `assets/images/novo_cliente/` e adicionar assets específicos.

### 4. Atualizar pubspec.yaml
Adicionar linha no assets:
```yaml
- assets/images/novo_cliente/
```

## Configurações por Cliente

Cada cliente pode ter configurações específicas:

### Temas
- Cores primárias e secundárias
- Estilos de botões
- Tipografia
- Outros elementos visuais

### APIs
- URLs de base diferentes por cliente
- Endpoints específicos

### Funcionalidades
- Features habilitadas/desabilitadas por cliente
- Limites específicos (ex: número máximo de usuários)
- Configurações personalizadas

### Assets
- Logos específicos
- Ícones personalizados
- Imagens de marca

## Compilação para Produção

Para compilar para um cliente específico:

1. **Configuração manual**: Alterar cliente padrão no `main.dart`
2. **Via build flavors**: Implementar flavors do Flutter (recomendado para produção)
3. **Via variáveis de ambiente**: Ler cliente de variável de ambiente

## Próximos Passos Recomendados

1. **Implementar Build Flavors**: Para builds automáticos por cliente
2. **Persistência**: Salvar cliente selecionado localmente
3. **Configuração Remota**: Buscar configurações de um servidor
4. **Testes**: Criar testes para cada configuração de cliente
5. **CI/CD**: Automatizar builds para cada cliente