import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/client_service.dart';
import '../services/storage_service.dart';
import '../models/criar_acesso_model.dart';
import '../models/login_model.dart';

class CriarAcessoScreen extends StatefulWidget {
  final String? documentoInicial;

  const CriarAcessoScreen({super.key, this.documentoInicial});

  @override
  State<CriarAcessoScreen> createState() => _CriarAcessoScreenState();
}

class _CriarAcessoScreenState extends State<CriarAcessoScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Documento
  final _documentoController = TextEditingController();
  final _documentoFormKey = GlobalKey<FormState>();
  bool _documentoValido = false;
  String _tipoDocumento = 'CPF'; // 'CPF' ou 'PASSAPORTE'

  // Fluxo de criação de conta (quando usuário não encontrado)
  bool _precisaCriarConta = false;
  final _nomeController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _criarContaFormKey = GlobalKey<FormState>();
  String? _generoSelecionado = 'PREFIRO NAO INFORMAR';
  final List<String> _generos = [
    'MASCULINO',
    'FEMININO',
    'NAO BINARIO',
    'PREFIRO NAO INFORMAR',
  ];

  // Step 2: Opções e código
  CriarAcessoOpcoesModel? _opcoesModel;
  OpcaoEnvioCodigoModel? _opcaoSelecionada;
  final _codigoController = TextEditingController();
  bool _codigoEnviado = false;
  int _tempoRestante = 0;
  Timer? _timer;

  // Step 3: Senha
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _senhaFormKey = GlobalKey<FormState>();
  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;

  @override
  void initState() {
    super.initState();

    // Listener para validar documento em tempo real
    _documentoController.addListener(() {
      final texto = _documentoController.text.trim();
      bool valido;

      if (_tipoDocumento == 'CPF') {
        valido = texto.isNotEmpty && texto.length == 11;
      } else {
        valido = texto.isNotEmpty && texto.length >= 8;
      }

      if (valido != _documentoValido) {
        setState(() {
          _documentoValido = valido;
        });
      }
    });

    // Configurar documento inicial (se fornecido)
    if (widget.documentoInicial != null) {
      _documentoController.text = widget.documentoInicial!;
      // Auto-detectar tipo de documento
      final doc = widget.documentoInicial!.trim();
      if (doc.length == 11 && RegExp(r'^\d+$').hasMatch(doc)) {
        _tipoDocumento = 'CPF';
      } else {
        _tipoDocumento = 'PASSAPORTE';
      }
      // Validar imediatamente o documento inicial
      _documentoValido = _tipoDocumento == 'CPF'
          ? (doc.isNotEmpty && doc.length == 11)
          : (doc.isNotEmpty && doc.length >= 8);
    }
  }

  @override
  void dispose() {
    _documentoController.dispose();
    _codigoController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _nomeController.dispose();
    _dataNascimentoController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com gradiente
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_add,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Flexible(
                              child: Text(
                                'Criar Novo Acesso',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Configure sua senha de acesso',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Indicador de progresso
                  _buildProgressIndicator(),
                  const SizedBox(height: 16),

                  // Conteúdo do step atual
                  if (_currentStep == 0) _buildStep1Documento(),
                  if (_currentStep == 1)
                    _precisaCriarConta
                        ? _buildStepCriarConta()
                        : _buildStep2Verificacao(),
                  if (_currentStep == 2) _buildStep3Sucesso(),

                  // Espaço extra para evitar overflow
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStepIndicator(0, 'Documento'),
        Expanded(child: _buildStepDivider(0)),
        _buildStepIndicator(1, _precisaCriarConta ? 'Dados' : 'Verificação'),
        Expanded(child: _buildStepDivider(1)),
        _buildStepIndicator(2, 'Concluir'),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green
                : isActive
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int step) {
    final isCompleted = step < _currentStep;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? Colors.green : Colors.grey.shade300,
    );
  }

  // Step 1: Informar documento
  Widget _buildStep1Documento() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _documentoFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.badge, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Informe seu Documento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Selecione o tipo de documento e digite as informações para continuar.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Radio buttons para tipo de documento
              Text(
                'Tipo de documento:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('CPF'),
                      value: 'CPF',
                      groupValue: _tipoDocumento,
                      onChanged: (value) {
                        setState(() {
                          _tipoDocumento = value!;
                          _documentoController.clear();
                          _documentoValido = false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Passaporte'),
                      value: 'PASSAPORTE',
                      groupValue: _tipoDocumento,
                      onChanged: (value) {
                        setState(() {
                          _tipoDocumento = value!;
                          _documentoController.clear();
                          _documentoValido = false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _documentoController,
                textInputAction: TextInputAction.done,
                contextMenuBuilder: (context, editableTextState) {
                  return const SizedBox.shrink(); // Desabilita o menu de contexto
                },
                inputFormatters: _tipoDocumento == 'CPF'
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ]
                    : [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(
                            text: newValue.text.toUpperCase().trim(),
                          );
                        }),
                        LengthLimitingTextInputFormatter(20),
                      ],
                decoration: InputDecoration(
                  labelText: _tipoDocumento == 'CPF' ? 'CPF' : 'Passaporte',
                  hintText: _tipoDocumento == 'CPF'
                      ? 'Digite apenas números'
                      : 'Digite letras e números',
                  prefixIcon: Icon(
                    _tipoDocumento == 'CPF'
                        ? Icons.person_outline
                        : Icons.flight,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_isLoading) return null;

                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite seu documento';
                  }

                  if (_tipoDocumento == 'CPF') {
                    if (value.length != 11) {
                      return 'CPF deve ter 11 dígitos';
                    }
                  } else {
                    if (value.length < 8) {
                      return 'Passaporte deve ter pelo menos 8 caracteres';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_isLoading || !_documentoValido)
                    ? null
                    : _buscarOpcoesAcesso,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 2: Verificação e código
  Widget _buildStep2Verificacao() {
    return Column(
      children: [
        // Card com informações do usuário
        Card(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usuário Encontrado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _opcoesModel?.usuarioNome ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Card de seleção de método
        if (!_codigoEnviado) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Como deseja receber o código?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecione um dos métodos abaixo para receber seu código de verificação:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Lista de opções
                  ...(_opcoesModel?.opcoesDisponiveis ?? []).map((opcao) {
                    return _buildOpcaoCard(opcao);
                  }),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _opcaoSelecionada == null || _isLoading
                        ? null
                        : _solicitarCodigo,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar Código'),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Card de inserção de código e senha
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _senhaFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Verificação e Senha',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Digite o código de 6 dígitos enviado para ${_opcaoSelecionada?.valorMascarado} e crie sua senha.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),

                    // Campo do código
                    TextFormField(
                      controller: _codigoController,
                      keyboardType: TextInputType.number,
                      contextMenuBuilder: (context, editableTextState) {
                        return const SizedBox.shrink(); // Desabilita o menu de contexto
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Código de Verificação',
                        hintText: '000000',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite o código';
                        }
                        if (value.length != 6) {
                          return 'Código deve ter 6 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Timer de reenvio
                    if (_tempoRestante > 0)
                      Text(
                        'Reenviar código em $_tempoRestante segundos',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      )
                    else
                      TextButton(
                        onPressed: _isLoading ? null : _solicitarCodigo,
                        child: const Text('Reenviar código'),
                      ),
                    const SizedBox(height: 20),

                    // Campo de senha
                    TextFormField(
                      controller: _senhaController,
                      obscureText: _obscureSenha,
                      contextMenuBuilder: (context, editableTextState) {
                        return const SizedBox.shrink(); // Desabilita o menu de contexto
                      },
                      decoration: InputDecoration(
                        labelText: 'Nova Senha',
                        hintText: 'Digite sua senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSenha
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureSenha = !_obscureSenha;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite uma senha';
                        }
                        if (value.length < 4) {
                          return 'Senha deve ter pelo menos 4 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo de confirmar senha
                    TextFormField(
                      controller: _confirmarSenhaController,
                      obscureText: _obscureConfirmarSenha,
                      contextMenuBuilder: (context, editableTextState) {
                        return const SizedBox.shrink(); // Desabilita o menu de contexto
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha',
                        hintText: 'Digite a senha novamente',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmarSenha
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmarSenha = !_obscureConfirmarSenha;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, confirme sua senha';
                        }
                        if (value != _senhaController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _concluirCriacaoAcesso,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Concluir Cadastro'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _codigoEnviado = false;
                          _opcaoSelecionada = null;
                          _codigoController.clear();
                          _senhaController.clear();
                          _confirmarSenhaController.clear();
                          _timer?.cancel();
                        });
                      },
                      child: const Text('Escolher outro método'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOpcaoCard(OpcaoEnvioCodigoModel opcao) {
    final isSelected = _opcaoSelecionada?.tipo == opcao.tipo;

    return GestureDetector(
      onTap: () {
        setState(() {
          _opcaoSelecionada = opcao;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                opcao.iconeNome == 'email' ? Icons.email : Icons.phone,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opcao.descricao,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opcao.valorMascarado,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

  // Step 3: Sucesso
  Widget _buildStep3Sucesso() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _precisaCriarConta
                  ? 'Conta Criada com Sucesso!'
                  : 'Acesso Criado com Sucesso!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _precisaCriarConta
                  ? 'Sua conta foi criada com sucesso!\nVocê já está logado no aplicativo.'
                  : 'Seu acesso foi criado com sucesso!\nVocê já está logado no aplicativo.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Volta para account_screen
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Buscar opções de acesso
  Future<void> _buscarOpcoesAcesso() async {
    // Verificar se o documento é válido primeiro
    final documento = _documentoController.text.trim();

    if (_tipoDocumento == 'CPF') {
      if (documento.isEmpty || documento.length != 11) {
        _showErrorDialog('Por favor, informe um CPF válido com 11 dígitos.');
        return;
      }
    } else {
      if (documento.isEmpty || documento.length < 8) {
        _showErrorDialog(
          'Por favor, informe um passaporte válido com pelo menos 8 caracteres.',
        );
        return;
      }
    }

    // Só então validar o formulário (para mostrar outros possíveis erros)
    if (!_documentoFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      final response = await apiService.getCriarAcessoOpcoes(
        clientService.currentConfig.clientType,
        documento,
      );

      if (response.success && response.data != null) {
        final opcoesModel = CriarAcessoOpcoesModel.fromJson(response.data!);
        setState(() {
          _opcoesModel = opcoesModel;
          _precisaCriarConta = false;
          _currentStep = 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        // Verificar se é erro de usuário não encontrado
        if (response.error?.contains('Usuário não encontrado') == true) {
          setState(() {
            _precisaCriarConta = true;
            _currentStep = 1;
          });
        } else {
          _showErrorDialog(
            response.error ?? 'Erro ao buscar opções de criação de acesso',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro inesperado: $e');
    }
  }

  // Solicitar código
  Future<void> _solicitarCodigo() async {
    if (_opcaoSelecionada == null || _opcoesModel == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      final response = await apiService.solicitarCodigoCriarAcesso(
        clientService.currentConfig.clientType,
        _opcoesModel!.usuarioId,
        _opcaoSelecionada!.tipo,
      );

      if (response.success) {
        setState(() {
          _codigoEnviado = true;
          _isLoading = false;
          _tempoRestante = 60;
        });

        // Iniciar timer de reenvio
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_tempoRestante > 0) {
              _tempoRestante--;
            } else {
              timer.cancel();
            }
          });
        });

        _showSuccessSnackBar('Código enviado com sucesso!');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(response.error ?? 'Erro ao solicitar código');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro inesperado: $e');
    }
  }

  // Concluir criação de acesso
  Future<void> _concluirCriacaoAcesso() async {
    if (!_senhaFormKey.currentState!.validate()) return;
    if (_opcoesModel == null || _opcaoSelecionada == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      final response = await apiService.concluirCriarAcesso(
        clientService.currentConfig.clientType,
        _opcoesModel!.usuarioId,
        _opcaoSelecionada!.tipo,
        _senhaController.text.trim(),
        _codigoController.text.trim(),
      );

      if (response.success && response.data != null) {
        // Fazer login automático com os dados retornados
        await _processarAutoLogin(response.data!);

        setState(() {
          _currentStep = 2; // Avança para a tela de sucesso
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          response.error ?? 'Erro ao concluir criação de acesso',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro inesperado: $e');
    }
  }

  // Selecionar data de nascimento
  Future<void> _selecionarDataNascimento() async {
    final DateTime agora = DateTime.now();
    final DateTime dataMinima = DateTime(agora.year - 120); // 120 anos atrás
    final DateTime dataMaxima = DateTime(agora.year - 16); // Mínimo 16 anos

    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: dataMaxima,
      firstDate: dataMinima,
      lastDate: dataMaxima,
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      fieldLabelText: 'Digite a data',
      fieldHintText: 'DD/MM/AAAA',
    );

    if (dataSelecionada != null) {
      final dataFormatada =
          '${dataSelecionada.day.toString().padLeft(2, '0')}/'
          '${dataSelecionada.month.toString().padLeft(2, '0')}/'
          '${dataSelecionada.year}';

      setState(() {
        _dataNascimentoController.text = dataFormatada;
      });
    }
  }

  // Criar nova conta
  Future<void> _criarNovaConta() async {
    if (!_criarContaFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      // Converter data de DD/MM/YYYY para YYYY-MM-DD
      final dataPartes = _dataNascimentoController.text.split('/');
      final dataFormatada =
          '${dataPartes[2]}-${dataPartes[1]}-${dataPartes[0]}';

      final dadosConta = {
        'tipo_documento': _tipoDocumento,
        'cpf': _documentoController.text.trim(),
        'nome': _nomeController.text.trim(),
        'data_nascimento': dataFormatada,
        'email': _emailController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'genero': _generoSelecionado,
        'senha': _senhaController.text.trim(),
        'app_2': true,
      };

      final response = await apiService.post(
        clientService.currentConfig.clientType,
        '/v-public/criar-conta',
        dadosConta,
      );

      if (response.success && response.data != null) {
        // Fazer login automático com os dados retornados
        await _processarAutoLoginCriacaoConta(response.data!);

        setState(() {
          _isLoading = false;
          _currentStep = 2; // Vai para a tela de sucesso
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(response.error ?? 'Erro ao criar conta');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro inesperado: $e');
    }
  }

  // Processar auto-login após criação de acesso (fluxo de usuário existente)
  Future<void> _processarAutoLogin(Map<String, dynamic> userData) async {
    try {
      final storageService = await StorageService.getInstance();
      // Criar objeto de login response (ele já faz a limpeza do token internamente)
      final loginResponse = LoginResponse.fromJson(userData);
      // Salvar dados de login (token + usuário)
      await storageService.saveLoginData(loginResponse);
      // Aguardar um pouco para garantir que o token foi persistido
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      // Não mostrar erro para o usuário, pois o acesso foi criado com sucesso
      // O usuário pode fazer login manualmente se necessário
    }
  }

  // Processar auto-login após criação de conta (novo usuário)
  Future<void> _processarAutoLoginCriacaoConta(
    Map<String, dynamic> userData,
  ) async {
    try {
      final storageService = await StorageService.getInstance();
      // Criar objeto de login response (ele já faz a limpeza do token internamente)
      final loginResponse = LoginResponse.fromJson(userData);
      // Salvar dados de login (token + usuário)
      await storageService.saveLoginData(loginResponse);
      // Aguardar um pouco para garantir que o token foi persistido
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      // Continuar mesmo com erro, pois a conta foi criada com sucesso
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Step: Criar nova conta
  Widget _buildStepCriarConta() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _criarContaFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Criar Nova Conta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Usuário não encontrado. Vamos criar uma nova conta para você.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Nome
              TextFormField(
                controller: _nomeController,
                textCapitalization: TextCapitalization.words,
                contextMenuBuilder: (context, editableTextState) {
                  return const SizedBox.shrink(); // Desabilita o menu de contexto
                },
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  hintText: 'Digite seu nome completo',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, digite seu nome';
                  }
                  if (value.trim().split(' ').length < 2) {
                    return 'Digite nome e sobrenome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Documento (readonly, já informado)
              TextFormField(
                controller: _documentoController,
                readOnly: true,
                contextMenuBuilder: (context, editableTextState) {
                  return const SizedBox.shrink(); // Desabilita o menu de contexto
                },
                decoration: InputDecoration(
                  labelText: _tipoDocumento,
                  prefixIcon: Icon(
                    _tipoDocumento == 'CPF'
                        ? Icons.person_outline
                        : Icons.flight,
                  ),
                  border: const OutlineInputBorder(),
                  fillColor: Colors.grey[100],
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),

              // Data de nascimento
              TextFormField(
                controller: _dataNascimentoController,
                readOnly: true,
                onTap: _selecionarDataNascimento,
                decoration: const InputDecoration(
                  labelText: 'Data de Nascimento',
                  hintText: 'Toque para selecionar',
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione sua data de nascimento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // E-mail
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                contextMenuBuilder: (context, editableTextState) {
                  return const SizedBox.shrink(); // Desabilita o menu de contexto
                },
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'Digite seu e-mail',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, digite seu e-mail';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value.trim())) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Telefone
              TextFormField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                contextMenuBuilder: (context, editableTextState) {
                  return const SizedBox.shrink(); // Desabilita o menu de contexto
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: 'Digite seu telefone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite seu telefone';
                  }
                  if (value.length < 10) {
                    return 'Telefone deve ter pelo menos 10 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gênero
              Text(
                'Gênero:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _generoSelecionado,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.wc),
                  border: OutlineInputBorder(),
                ),
                items: _generos.map((genero) {
                  return DropdownMenuItem(value: genero, child: Text(genero));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _generoSelecionado = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecione seu gênero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Senha
              TextFormField(
                controller: _senhaController,
                obscureText: _obscureSenha,
                contextMenuBuilder: (context, editableTextState) {
                  return const SizedBox.shrink(); // Desabilita o menu de contexto
                },
                decoration: InputDecoration(
                  labelText: 'Senha',
                  hintText: 'Digite sua senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureSenha ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureSenha = !_obscureSenha;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite uma senha';
                  }
                  if (value.length < 4) {
                    return 'Senha deve ter pelo menos 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmar Senha
              TextFormField(
                controller: _confirmarSenhaController,
                obscureText: _obscureConfirmarSenha,
                contextMenuBuilder: (context, editableTextState) {
                  return const SizedBox.shrink(); // Desabilita o menu de contexto
                },
                decoration: InputDecoration(
                  labelText: 'Confirmar Senha',
                  hintText: 'Digite a senha novamente',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmarSenha
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmarSenha = !_obscureConfirmarSenha;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme sua senha';
                  }
                  if (value != _senhaController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : _criarNovaConta,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Criar Conta'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _precisaCriarConta = false;
                    _documentoController.clear();
                    _nomeController.clear();
                    _dataNascimentoController.clear();
                    _emailController.clear();
                    _telefoneController.clear();
                    _senhaController.clear();
                    _confirmarSenhaController.clear();
                    _generoSelecionado = 'PREFIRO NAO INFORMAR';
                    _documentoValido = false;
                  });
                },
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Erro'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
