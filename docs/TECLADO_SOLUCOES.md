# 🎹 Soluções para Teclado no Flutter

## Problema
O teclado não tem botão "OK" ou "Concluído" e fica aberto indefinidamente.

## ✅ Solução 1: textInputAction (Recomendado)

Adicione a propriedade `textInputAction` em todos os seus campos de texto:

```dart
TextFormField(
  decoration: InputDecoration(labelText: 'Nome'),
  textInputAction: TextInputAction.done,  // ← ADICIONAR ISSO
  onFieldSubmitted: (value) {
    // Fecha o teclado quando pressiona "Concluído"
    FocusScope.of(context).unfocus();
  },
)
```

### Opções de textInputAction:

- **`TextInputAction.done`** - Mostra "Concluído" (último campo do formulário)
- **`TextInputAction.next`** - Mostra "Próximo" (move para próximo campo)
- **`TextInputAction.go`** - Mostra "Ir" (para buscas/navegação)
- **`TextInputAction.search`** - Mostra "Buscar" (para campos de pesquisa)
- **`TextInputAction.send`** - Mostra "Enviar" (para mensagens)

### Exemplo completo:

```dart
Column(
  children: [
    TextFormField(
      decoration: InputDecoration(labelText: 'Nome'),
      textInputAction: TextInputAction.next, // Próximo campo
    ),
    TextFormField(
      decoration: InputDecoration(labelText: 'Email'),
      textInputAction: TextInputAction.next, // Próximo campo
      keyboardType: TextInputType.emailAddress,
    ),
    TextFormField(
      decoration: InputDecoration(labelText: 'Telefone'),
      textInputAction: TextInputAction.done, // Último campo
      keyboardType: TextInputType.phone,
      onFieldSubmitted: (value) {
        FocusScope.of(context).unfocus(); // Fecha teclado
      },
    ),
  ],
)
```

## ✅ Solução 2: Fechar teclado ao tocar fora

Adicione um `GestureDetector` que detecta toques fora dos campos:

```dart
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      // Fecha teclado ao tocar em qualquer lugar
      FocusScope.of(context).unfocus();
    },
    child: Scaffold(
      appBar: AppBar(title: Text('Formulário')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Seus campos aqui
          ],
        ),
      ),
    ),
  );
}
```

## ✅ Solução 3: Botão manual para fechar teclado

Adicione um botão que fecha o teclado manualmente:

```dart
ElevatedButton(
  onPressed: () {
    FocusScope.of(context).unfocus();
  },
  child: Text('Fechar Teclado'),
)
```

## ✅ Solução 4: Comportamento automático com Form

Use `Form` com `FocusNode` para controlar melhor o foco:

```dart
class MyFormScreen extends StatefulWidget {
  @override
  _MyFormScreenState createState() => _MyFormScreenState();
}

class _MyFormScreenState extends State<MyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_emailFocus);
              },
            ),
            TextFormField(
              focusNode: _emailFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_phoneFocus);
              },
            ),
            TextFormField(
              focusNode: _phoneFocus,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                FocusScope.of(context).unfocus();
                // Ou submeter o formulário:
                // if (_formKey.currentState!.validate()) {
                //   _submitForm();
                // }
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🎯 Recomendação Final

**Combine as soluções 1 e 2:**

```dart
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Scaffold(
      body: Form(
        child: Column(
          children: [
            TextFormField(
              textInputAction: TextInputAction.next,
              // ... outros campos
            ),
            TextFormField(
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ],
        ),
      ),
    ),
  );
}
```

## 📱 Comportamento por plataforma

- **iOS**: Sempre mostra o botão configurado em `textInputAction`
- **Android**: Depende do teclado, mas geralmente mostra também
- **Web**: Usa Enter padrão

## 🔧 Troubleshooting

### Teclado não fecha no iOS
```dart
// Use isso para forçar o fechamento:
SystemChannels.textInput.invokeMethod('TextInput.hide');
```

### Teclado reabre automaticamente
```dart
// Certifique-se de não estar re-focando o campo:
FocusScope.of(context).unfocus();
FocusManager.instance.primaryFocus?.unfocus();
```

### TextField numérico sem "OK"
```dart
TextFormField(
  keyboardType: TextInputType.number,
  textInputAction: TextInputAction.done, // ← Importante!
  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
)
```
