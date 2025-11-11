import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/cortesia_link_model.dart';
import '../services/api_service.dart';
import '../services/client_service.dart';

class CortesiaLinkScreen extends StatefulWidget {
  final String cortesiaId;

  const CortesiaLinkScreen({super.key, required this.cortesiaId});

  @override
  State<CortesiaLinkScreen> createState() => _CortesiaLinkScreenState();
}

class _CortesiaLinkScreenState extends State<CortesiaLinkScreen> {
  CortesiaLinkModel? _cortesia;
  bool _isLoading = true;
  String? _errorMessage;

  final List<ConvidadoFormData> _convidados = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _carregarCortesia();
  }

  Future<void> _carregarCortesia() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      final response = await apiService.getCortesiaLink(
        clientService.currentConfig.clientType,
        widget.cortesiaId,
      );

      if (response.success && response.data != null) {
        final cortesia = CortesiaLinkModel.fromJson(response.data!);

        // Se não pode ser preenchida, verificar o motivo
        if (!cortesia.podeSerPreenchida) {
          // Se já foi preenchida (status diferente de AGUARDANDO VINCULO)
          // Mostrar tela de sucesso com os QR Codes
          if (cortesia.status != 'AGUARDANDO VINCULO' &&
              cortesia.versaoCortesia == 2) {
            setState(() {
              _cortesia = cortesia;
              _isLoading = false;
            });
            // Navegar diretamente para tela de sucesso
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CortesiaSucessoScreen(cortesiaData: response.data!),
                ),
              );
            });
            return;
          }

          // Outros motivos de erro
          setState(() {
            _errorMessage = cortesia.versaoCortesia != 2
                ? 'Esta cortesia não está disponível para preenchimento'
                : _getMensagemStatus(cortesia.status);
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _cortesia = cortesia;
          _isLoading = false;

          // Inicializar formulários dos convidados
          for (int i = 0; i < cortesia.cortesiasDisponiveis; i++) {
            _convidados.add(ConvidadoFormData(index: i));
          }
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Erro ao carregar cortesia';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro inesperado: $e';
        _isLoading = false;
      });
    }
  }

  String _getMensagemStatus(String status) {
    switch (status.toUpperCase()) {
      case 'AGUARDANDO VINCULO':
      case 'AGUARDANDO_VINCULO':
        return 'Esta cortesia está aguardando preenchimento';
      case 'PENDENTE':
        return 'Esta cortesia já foi preenchida e está pendente de retirada';
      case 'PARCIALMENTE_RETIRADA':
      case 'PARCIALMENTE RETIRADA':
        return 'Esta cortesia foi parcialmente retirada';
      case 'RETIRADA':
        return 'Esta cortesia já foi totalmente retirada';
      case 'CANCELADA':
        return 'Esta cortesia foi cancelada';
      case 'EXPIRADA':
        return 'Esta cortesia está expirada';
      default:
        return 'Esta cortesia não está disponível para preenchimento (Status: $status)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Concluir Reserva'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildFormView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        // Conteúdo rolável
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header com informações da cortesia
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data da Reserva: ${DateFormat('dd/MM/yyyy').format(_cortesia!.data)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Título: ${_cortesia!.titulo.nomeSerie} - ${_cortesia!.titulo.titulo}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_cortesia!.cortesiasDisponiveis} ${_cortesia!.cortesiasDisponiveis == 1 ? 'convidado' : 'convidados'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Instruções
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Instruções',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Preencha os dados de cada convidado\n'
                        '• Para brasileiros, use CPF. Para estrangeiros, use Passaporte\n'
                        '• Todos os campos são obrigatórios\n'
                        '• Se o convidado for responsável por um menor de idade, marque a opção e preencha os dados do menor',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Formulário dos convidados
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _convidados.asMap().entries.map((entry) {
                        return _buildConvidadoForm(entry.key);
                      }).toList(),
                    ),
                  ),
                ),

                // Botão de envio
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submeterFormulario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirmar Convidados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConvidadoForm(int index) {
    final convidado = _convidados[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convidado ${index + 1}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Radio CPF ou Passaporte
            const Text(
              'Tipo de Documento *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('CPF'),
                    value: 'cpf',
                    groupValue: convidado.tipoDocumento,
                    onChanged: (value) {
                      setState(() {
                        convidado.tipoDocumento = value!;
                        convidado.documentoController.clear();
                        convidado.nomeController.clear();
                        convidado.telefoneController.clear();
                        convidado.dataNascimentoController.clear();
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Passaporte'),
                    value: 'passaporte',
                    groupValue: convidado.tipoDocumento,
                    onChanged: (value) {
                      setState(() {
                        convidado.tipoDocumento = value!;
                        convidado.documentoController.clear();
                        convidado.nomeController.clear();
                        convidado.telefoneController.clear();
                        convidado.dataNascimentoController.clear();
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Campo Documento
            TextFormField(
              controller: convidado.documentoController,
              decoration: InputDecoration(
                labelText: convidado.tipoDocumento == 'cpf'
                    ? 'CPF *'
                    : 'Passaporte *',
                hintText: convidado.tipoDocumento == 'cpf'
                    ? '000.000.000-00'
                    : 'ABC123456',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.badge),
              ),
              keyboardType: convidado.tipoDocumento == 'cpf'
                  ? TextInputType.number
                  : TextInputType.text,
              inputFormatters: convidado.tipoDocumento == 'cpf'
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      _CpfInputFormatter(),
                    ]
                  : [LengthLimitingTextInputFormatter(20)],
              onChanged: (value) {
                if (convidado.tipoDocumento == 'cpf' && value.length == 14) {
                  _buscarUsuarioPorCpf(
                    convidado,
                    value.replaceAll(RegExp(r'\D'), ''),
                  );
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                if (convidado.tipoDocumento == 'cpf') {
                  final cpf = value.replaceAll(RegExp(r'\D'), '');
                  if (cpf.length != 11) {
                    return 'CPF inválido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Campo Nome
            TextFormField(
              controller: convidado.nomeController,
              decoration: InputDecoration(
                labelText: 'Nome Completo *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Campo Telefone
            TextFormField(
              controller: convidado.telefoneController,
              decoration: InputDecoration(
                labelText: 'Telefone *',
                hintText: '(00) 00000-0000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                _TelefoneInputFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                final telefone = value.replaceAll(RegExp(r'\D'), '');
                if (telefone.length < 10) {
                  return 'Telefone inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Campo Data de Nascimento
            TextFormField(
              controller: convidado.dataNascimentoController,
              decoration: InputDecoration(
                labelText: 'Data de Nascimento *',
                hintText: 'DD/MM/AAAA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
                _DataInputFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                if (value.length != 10) {
                  return 'Data inválida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Checkbox Responsável por Menor
            CheckboxListTile(
              title: const Text(
                'Responsável por menor de idade',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Marque se este convidado levará um menor de idade',
                style: TextStyle(fontSize: 12),
              ),
              value: convidado.responsavelPorMenor,
              onChanged: (value) {
                setState(() {
                  convidado.responsavelPorMenor = value ?? false;
                  if (!convidado.responsavelPorMenor) {
                    convidado.nomeMenorController.clear();
                    convidado.dataNascimentoMenorController.clear();
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Campos do Menor
            if (convidado.responsavelPorMenor) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.child_care, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Dados do Menor',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: convidado.nomeMenorController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Menor *',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (convidado.responsavelPorMenor &&
                            (value == null || value.isEmpty)) {
                          return 'Campo obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: convidado.dataNascimentoMenorController,
                      decoration: InputDecoration(
                        labelText: 'Data de Nascimento do Menor *',
                        hintText: 'DD/MM/AAAA',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                        _DataInputFormatter(),
                      ],
                      validator: (value) {
                        if (convidado.responsavelPorMenor &&
                            (value == null || value.isEmpty)) {
                          return 'Campo obrigatório';
                        }
                        if (convidado.responsavelPorMenor &&
                            value!.length != 10) {
                          return 'Data inválida';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Checkbox de aceite de termos (OBRIGATÓRIO)
            const SizedBox(height: 16),
            CheckboxListTile(
              title: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    const TextSpan(text: 'Concordo com os '),
                    TextSpan(
                      text: 'termos de uso',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' e '),
                    TextSpan(
                      text: 'políticas de privacidade',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              value: convidado.aceitouTermos,
              onChanged: (value) {
                setState(() {
                  convidado.aceitouTermos = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (!convidado.aceitouTermos && convidado.tentouEnviar)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'Você deve aceitar os termos para continuar',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _buscarUsuarioPorCpf(
    ConvidadoFormData convidado,
    String cpf,
  ) async {
    try {
      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      final response = await apiService.buscarUsuarioPorDocumento(
        clientService.currentConfig.clientType,
        cpf,
      );

      if (response.success && response.data != null) {
        final usuario = UsuarioGeralModel.fromJson(response.data!);

        setState(() {
          convidado.nomeController.text = usuario.nome;
          convidado.telefoneController.text = usuario.telefone;
          convidado.dataNascimentoController.text = usuario.dataNascimento;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dados preenchidos automaticamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Silenciosamente falha se não encontrar
    }
  }

  void _submeterFormulario() async {
    if (_formKey.currentState!.validate()) {
      // Verificar se todos aceitaram os termos
      bool todosAceitaram = true;
      for (var convidado in _convidados) {
        convidado.tentouEnviar = true;
        if (!convidado.aceitouTermos) {
          todosAceitaram = false;
        }
      }

      if (!todosAceitaram) {
        setState(() {}); // Atualizar UI para mostrar erros
        _mostrarErro(
          'Todos os convidados devem aceitar os termos para continuar',
        );
        return;
      }

      // Validar idades antes de enviar
      if (!_validarIdades()) {
        return;
      }

      try {
        // Construir payload
        final payload = _construirPayload();

        // Mostrar loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final apiService = await ApiService.getInstance();
        final clientService = ClientService.instance;

        final response = await apiService.enviarCortesiaLink(
          clientService.currentConfig.clientType,
          payload,
        );

        if (!mounted) return;
        Navigator.pop(context); // Fechar loading

        if (response.success) {
          // Recarregar a cortesia com os dados preenchidos
          final cortesiaAtualizada = await apiService.getCortesiaLink(
            clientService.currentConfig.clientType,
            widget.cortesiaId,
          );

          if (!mounted) return;

          if (cortesiaAtualizada.success && cortesiaAtualizada.data != null) {
            // Navegar para tela de sucesso com QR Codes
            Navigator.pop(context); // Fechar tela atual
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CortesiaSucessoScreen(
                  cortesiaData: cortesiaAtualizada.data!,
                ),
              ),
            );
          } else {
            // Se não conseguir carregar, mostrar dialog simples
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text('Sucesso!'),
                  ],
                ),
                content: const Text('Reserva confirmada com sucesso!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Fechar dialog
                      Navigator.pop(context); // Voltar para tela anterior
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          // Erro
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  const Text('Erro'),
                ],
              ),
              content: Text(response.error ?? 'Erro ao confirmar reserva'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Fechar loading

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro'),
            content: Text('Erro inesperado: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  bool _validarIdades() {
    for (int i = 0; i < _convidados.length; i++) {
      final convidado = _convidados[i];

      // Validar data do convidado principal ou adulto
      final dataNascimento = _parseData(
        convidado.dataNascimentoController.text,
      );
      if (dataNascimento == null) {
        _mostrarErro('Convidado ${i + 1}: Data de nascimento inválida');
        return false;
      }

      // Verificar se é maior de idade (18 anos)
      final idade = _calcularIdade(dataNascimento);

      // Se marcou "responsável por menor", o adulto DEVE ser maior de idade
      if (convidado.responsavelPorMenor) {
        if (idade < 18) {
          _mostrarErro(
            'Convidado ${i + 1}: Responsável deve ter 18 anos ou mais',
          );
          return false;
        }

        // Validar data do menor
        final dataMenor = _parseData(
          convidado.dataNascimentoMenorController.text,
        );
        if (dataMenor == null) {
          _mostrarErro(
            'Convidado ${i + 1}: Data de nascimento do menor inválida',
          );
          return false;
        }

        final idadeMenor = _calcularIdade(dataMenor);
        if (idadeMenor >= 18) {
          _mostrarErro('Convidado ${i + 1}: O menor deve ter menos de 18 anos');
          return false;
        }
      }
    }

    return true;
  }

  void _mostrarErro(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Atenção'),
          ],
        ),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  DateTime? _parseData(String data) {
    try {
      // Formato: DD/MM/AAAA
      final parts = data.split('/');
      if (parts.length != 3) return null;

      final dia = int.parse(parts[0]);
      final mes = int.parse(parts[1]);
      final ano = int.parse(parts[2]);

      return DateTime(ano, mes, dia);
    } catch (e) {
      return null;
    }
  }

  String _formatarDataISO(String data) {
    // Converte DD/MM/AAAA para YYYY-MM-DD
    final parts = data.split('/');
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  int _calcularIdade(DateTime dataNascimento) {
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;

    if (hoje.month < dataNascimento.month ||
        (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }

    return idade;
  }

  Map<String, dynamic> _construirPayload() {
    final convidadosData = _convidados.map((c) {
      final dataNascimento = _parseData(c.dataNascimentoController.text)!;
      final isMaiorIdade = _calcularIdade(dataNascimento) >= 18;
      final isPassport = c.tipoDocumento == 'passaporte';

      // Se NÃO é responsável por menor: adulto é o principal
      if (!c.responsavelPorMenor) {
        return {
          'idade_verificada': true,
          'check_termo': c.aceitouTermos,
          'is_maior_idade': isMaiorIdade,
          'is_passport': isPassport,
          'nome': c.nomeController.text,
          'cpf': c.documentoController.text.replaceAll(RegExp(r'\D'), ''),
          'telefone': c.telefoneController.text.replaceAll(RegExp(r'\D'), ''),
          'nascimento': _formatarDataISO(c.dataNascimentoController.text),
        };
      } else {
        // Se É responsável por menor: menor é o principal, adulto é responsável
        final dataMenor = _parseData(c.dataNascimentoMenorController.text)!;
        final isMenorMaiorIdade = _calcularIdade(dataMenor) >= 18;

        return {
          'idade_verificada': true,
          'check_termo': c.aceitouTermos,
          'is_maior_idade': isMenorMaiorIdade, // sempre false (é menor)
          'is_passport': false, // menor não tem opção de passaporte
          'nome': c.nomeMenorController.text,
          'nascimento': _formatarDataISO(c.dataNascimentoMenorController.text),
          // Dados do responsável
          'nome_responsavel': c.nomeController.text,
          'cpf_responsavel': c.documentoController.text.replaceAll(
            RegExp(r'\D'),
            '',
          ),
          'telefone_responsavel': c.telefoneController.text.replaceAll(
            RegExp(r'\D'),
            '',
          ),
          'nascimento_responsavel': _formatarDataISO(
            c.dataNascimentoController.text,
          ),
        };
      }
    }).toList();

    return {'cortesia': widget.cortesiaId, 'convidados': convidadosData};
  }
}

class ConvidadoFormData {
  final int index;
  String tipoDocumento = 'cpf';
  final TextEditingController documentoController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController dataNascimentoController =
      TextEditingController();
  bool responsavelPorMenor = false;
  final TextEditingController nomeMenorController = TextEditingController();
  final TextEditingController dataNascimentoMenorController =
      TextEditingController();
  bool aceitouTermos = false;
  bool tentouEnviar = false;

  ConvidadoFormData({required this.index});
}

// Formatadores personalizados
class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write('.');
      } else if (i == 9) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 0) {
        buffer.write('(');
      } else if (i == 2) {
        buffer.write(') ');
      } else if (i == 7 && text.length == 11) {
        buffer.write('-');
      } else if (i == 6 && text.length == 10) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// ============================================================================
// Tela de Sucesso com QR Codes
// ============================================================================

class CortesiaSucessoScreen extends StatelessWidget {
  final Map<String, dynamic> cortesiaData;

  const CortesiaSucessoScreen({super.key, required this.cortesiaData});

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return 'Pendente';
      case 'PARCIALMENTE_RETIRADA':
      case 'PARCIALMENTE RETIRADA':
        return 'Parcialmente Retirada';
      case 'RETIRADA':
        return 'Retirada';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return Colors.orange;
      case 'PARCIALMENTE_RETIRADA':
      case 'PARCIALMENTE RETIRADA':
        return Colors.blue;
      case 'RETIRADA':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = cortesiaData['status'] as String? ?? 'PENDENTE';
    final convidados = cortesiaData['convidados'] as List? ?? [];
    final data = cortesiaData['data'] as String?;
    final titulo = cortesiaData['titulo'] as Map<String, dynamic>?;
    final tipoCortesia = cortesiaData['tipo_cortesia'] as String?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Reserva Confirmada'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header de sucesso
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Reserva Confirmada!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seus convidados foram registrados com sucesso',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Informações da reserva
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Detalhes da Reserva',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (data != null) ...[
                    _buildInfoRow(
                      'Data',
                      DateFormat('dd/MM/yyyy').format(DateTime.parse(data)),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (titulo != null) ...[
                    _buildInfoRow(
                      'Título',
                      '${titulo['nome_serie']} - ${titulo['titulo']}',
                      Icons.confirmation_number,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (tipoCortesia != null) ...[
                    _buildInfoRow(
                      'Tipo de Cortesia',
                      _formatarTipoCortesia(tipoCortesia),
                      Icons.local_offer,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildInfoRow(
                    'Total de Convidados',
                    '${convidados.length}',
                    Icons.people,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${_getStatusText(status)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de convidados com QR Codes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR Codes dos Convidados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Apresente os QR Codes abaixo na portaria',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ...convidados.asMap().entries.map((entry) {
                    final index = entry.key;
                    final convidado = entry.value as Map<String, dynamic>;
                    return _buildConvidadoCard(context, convidado, index + 1);
                  }).toList(),
                ],
              ),
            ),

            // Botão voltar
            Padding(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(
                      'Voltar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConvidadoCard(
    BuildContext context,
    Map<String, dynamic> convidado,
    int numero,
  ) {
    final nome = convidado['nome'] as String? ?? 'Sem nome';
    final cpf = convidado['cpf'] as String? ?? '';
    final telefone = convidado['telefone'] as String? ?? '';
    final dataNascimento = convidado['data_nascimento'] as String?;
    final hash2 = convidado['hash_2'] as String? ?? '';
    final retirado = convidado['retirado'] as bool? ?? false;
    final dataRetirada = convidado['data_hora_retirada'] as String?;

    // Dados do menor (quando existe pessoa_menor_idade)
    final pessoaMenorIdade =
        convidado['pessoa_menor_idade'] as Map<String, dynamic>?;
    final nomeMenor = pessoaMenorIdade?['nome'] as String?;
    final dataNascimentoMenor = pessoaMenorIdade?['data_nascimento'] as String?;
    final temMenor = pessoaMenorIdade != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header do convidado (Responsável)
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: retirado
                      ? Colors.green.shade100
                      : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    '$numero',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: retirado
                          ? Colors.green.shade700
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (temMenor)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Responsável',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (cpf.isNotEmpty)
                        Text(
                          'Documento: ${_formatarCpf(cpf)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (telefone.isNotEmpty)
                        Text(
                          'Tel: ${_formatarTelefone(telefone)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (dataNascimento != null)
                        Text(
                          'Nascimento: ${_formatarDataNascimento(dataNascimento)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (retirado)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Retirado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (retirado && dataRetirada != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Retirado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dataRetirada))}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            // Informações do Menor de Idade
            if (temMenor && nomeMenor != null) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.child_care,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Menor de Idade',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nomeMenor,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (dataNascimentoMenor != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.cake,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatarDataNascimento(dataNascimentoMenor),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const Divider(height: 24),

            // QR Code
            if (hash2.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: QrImageView(
                  data: hash2,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Código: ${hash2.substring(0, 20)}...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QR Code não disponível',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatarCpf(String cpf) {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
  }

  String _formatarTelefone(String telefone) {
    // Remove caracteres não numéricos
    final numeros = telefone.replaceAll(RegExp(r'\D'), '');

    if (numeros.length == 11) {
      // (00) 00000-0000
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    } else if (numeros.length == 10) {
      // (00) 0000-0000
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    }
    return telefone;
  }

  String _formatarTipoCortesia(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'PROMOCIONAL':
        return 'Promocional';
      case 'CORTESIA':
        return 'Cortesia';
      case 'TRANSFERENCIA':
        return 'Transferência';
      case 'EVENTO':
        return 'Evento';
      default:
        return tipo;
    }
  }

  String _formatarDataNascimento(String dataISO) {
    try {
      final data = DateTime.parse(dataISO);
      return DateFormat('dd/MM/yyyy').format(data);
    } catch (e) {
      return dataISO;
    }
  }
}
