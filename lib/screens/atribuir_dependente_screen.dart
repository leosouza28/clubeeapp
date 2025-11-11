import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/parentesco_model.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';

// Formatador de CPF
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 3 || i == 6) {
        buffer.write('.');
      } else if (i == 9) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formatador de Telefone
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 0) {
        buffer.write('(');
      } else if (i == 2) {
        buffer.write(')');
      } else if (i == 7) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AtribuirDependenteScreen extends StatefulWidget {
  final String tituloId;
  final String dependenteHash;

  const AtribuirDependenteScreen({
    super.key,
    required this.tituloId,
    required this.dependenteHash,
  });

  @override
  State<AtribuirDependenteScreen> createState() =>
      _AtribuirDependenteScreenState();
}

class _AtribuirDependenteScreenState extends State<AtribuirDependenteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isMenorIdade = false;
  List<ParentescoModel> _parentescos = [];
  bool _isLoadingParentescos = true;

  // Controladores de formulário
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  String? _selectedTipoDocumento = 'CPF';
  String? _selectedSexo;
  String? _selectedParentesco;
  DateTime? _dataNascimento;

  final List<String> _sexoOptions = [
    'MASCULINO',
    'FEMININO',
    'NAO BINARIO',
    'PREFIRO NAO INFORMAR',
  ];

  @override
  void initState() {
    super.initState();
    _loadParentescos();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  Future<void> _loadParentescos() async {
    setState(() => _isLoadingParentescos = true);

    try {
      final clientService = ClientService.instance;
      final authService = await AuthService.getInstance();

      final result = await authService.getParentescos(
        clientService.currentConfig.clientType,
      );

      if (result.success && result.data != null) {
        setState(() {
          _parentescos = result.data!
              .map((json) => ParentescoModel.fromJson(json))
              .toList();
          _isLoadingParentescos = false;
        });
      } else {
        setState(() => _isLoadingParentescos = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Erro ao carregar parentescos'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingParentescos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() {
        _dataNascimento = picked;
        _dataNascimentoController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final clientService = ClientService.instance;
      final authService = await AuthService.getInstance();

      // Monta o body da requisição
      final Map<String, dynamic> body = {
        'id_titulo': widget.tituloId,
        'hash': widget.dependenteHash,
        'nome': _nomeController.text.trim(),
        'parentesco': _selectedParentesco,
        'genero': _selectedSexo,
        'data_nascimento': _dataNascimento?.toIso8601String().split('T')[0],
        'is_menor_idade': _isMenorIdade,
      };

      // Adiciona campos adicionais se não for menor de idade
      if (!_isMenorIdade) {
        body['tipo_documento'] = _selectedTipoDocumento;
        // Remove máscaras antes de enviar
        body['cpf_cnpj'] = _documentoController.text.replaceAll(
          RegExp(r'\D'),
          '',
        );
        body['email'] = _emailController.text.trim();
        body['telefone'] = _telefoneController.text.replaceAll(
          RegExp(r'\D'),
          '',
        );
      }

      final result = await authService.atribuirVagaDependente(
        clientService.currentConfig.clientType,
        body,
      );

      setState(() => _isLoading = false);

      if (result.success) {
        if (mounted) {
          // Mostra mensagem de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dependente atribuído com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Volta para a tela anterior e indica sucesso para recarregar
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Erro ao atribuir dependente'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atribuir Dependente'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      body: _isLoadingParentescos
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando informações...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informação do Hash
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hash do Dependente',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.dependenteHash,
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Checkbox Menor de Idade
                    CheckboxListTile(
                      title: const Text(
                        'Menor de idade',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Marque se o dependente for menor de 18 anos',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _isMenorIdade,
                      onChanged: (value) {
                        setState(() {
                          _isMenorIdade = value ?? false;
                          // Limpa campos não necessários
                          if (_isMenorIdade) {
                            _emailController.clear();
                            _documentoController.clear();
                            _telefoneController.clear();
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),

                    // Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: 'Nome Completo *',
                        hintText: 'Digite o nome completo',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Tipo de Documento e Documento (se não for menor)
                    if (!_isMenorIdade) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedTipoDocumento,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Documento *',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['CPF', 'Passaporte']
                            .map(
                              (tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(tipo),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTipoDocumento = value;
                            _documentoController.clear();
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tipo de documento é obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _documentoController,
                        decoration: InputDecoration(
                          labelText:
                              '${_selectedTipoDocumento ?? 'Documento'} *',
                          hintText: _selectedTipoDocumento == 'CPF'
                              ? '000.000.000-00'
                              : 'Número do passaporte',
                          prefixIcon: const Icon(Icons.credit_card),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: _selectedTipoDocumento == 'CPF'
                            ? TextInputType.number
                            : TextInputType.text,
                        inputFormatters: _selectedTipoDocumento == 'CPF'
                            ? [
                                FilteringTextInputFormatter.digitsOnly,
                                CpfInputFormatter(),
                              ]
                            : null,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Documento é obrigatório';
                          }
                          if (_selectedTipoDocumento == 'CPF') {
                            final digitsOnly = value.replaceAll(
                              RegExp(r'\D'),
                              '',
                            );
                            if (digitsOnly.length != 11) {
                              return 'CPF deve ter 11 dígitos';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // E-mail
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'E-mail *',
                          hintText: 'email@exemplo.com',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'E-mail é obrigatório';
                          }
                          if (!value.contains('@')) {
                            return 'E-mail inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Telefone
                      TextFormField(
                        controller: _telefoneController,
                        decoration: InputDecoration(
                          labelText: 'Telefone *',
                          hintText: '(91) 99999-9999',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TelefoneInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Telefone é obrigatório';
                          }
                          final digitsOnly = value.replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          if (digitsOnly.length < 10) {
                            return 'Telefone inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Data de Nascimento
                    TextFormField(
                      controller: _dataNascimentoController,
                      decoration: InputDecoration(
                        labelText: 'Data de Nascimento *',
                        hintText: 'dd/mm/aaaa',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Data de nascimento é obrigatória';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sexo
                    DropdownButtonFormField<String>(
                      value: _selectedSexo,
                      decoration: InputDecoration(
                        labelText: 'Sexo *',
                        prefixIcon: const Icon(Icons.wc),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _sexoOptions
                          .map(
                            (sexo) => DropdownMenuItem(
                              value: sexo,
                              child: Text(sexo.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedSexo = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sexo é obrigatório';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Parentesco
                    DropdownButtonFormField<String>(
                      value: _selectedParentesco,
                      decoration: InputDecoration(
                        labelText: 'Parentesco *',
                        prefixIcon: const Icon(Icons.family_restroom),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _parentescos
                          .map(
                            (parentesco) => DropdownMenuItem(
                              value: parentesco.value,
                              child: Text(parentesco.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedParentesco = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Parentesco é obrigatório';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Botão de enviar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                            : const Text(
                                'Atribuir Dependente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
