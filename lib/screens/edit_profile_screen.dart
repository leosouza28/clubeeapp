import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/client_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCepLoading = false;
  bool _isEstadosLoading = false;
  bool _isCidadesLoading = false;
  UserModel? _currentUser;

  // Controllers para campos editáveis
  final _rgController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _complementoController = TextEditingController();

  // Estados selecionados
  String? _estadoCivilSelecionado;
  String? _generoSelecionado;
  String? _estadoSelecionado;
  String? _cidadeSelecionada;

  // Listas dinâmicas
  List<Map<String, dynamic>> _estados = [];
  List<Map<String, dynamic>> _cidades = [];

  // Opções para dropdowns
  final List<String> _estadosCivis = [
    'SOLTEIRO',
    'CASADO',
    'DIVORCIADO',
    'VIUVO',
    'UNIAO ESTAVEL',
    'SEPARADO',
  ];

  final List<String> _generos = [
    'MASCULINO',
    'FEMININO',
    'NAO BINARIO',
    'PREFIRO NAO INFORMAR',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadEstados();
  }

  @override
  void dispose() {
    _rgController.dispose();
    _dataNascimentoController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;
      final result = await authService.getLoggedUserData(
        clientService.currentConfig.clientType,
      );

      if (result.success && result.user != null) {
        setState(() {
          _currentUser = result.user!;
          _isLoading = false;
        });
        _populateFields(result.user!);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorToast(result.error ?? 'Erro ao carregar dados do usuário');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Erro inesperado: $e');
    }
  }

  void _populateFields(UserModel user) {
    _rgController.text = user.rg ?? '';
    // Usar dataNascimento (string) diretamente para exibição
    _dataNascimentoController.text = _formatDateFromString(user.dataNascimento);
    _emailController.text = user.email;
    _telefoneController.text = user.numeroTelefoneAcesso;

    // Definir estados selecionados
    _estadoCivilSelecionado = user.estadoCivil;
    _generoSelecionado = user.genero;

    // Preencher endereço diretamente dos campos do usuário
    _cepController.text = user.enderecoCep ?? '';
    _logradouroController.text = user.enderecoLogradouro ?? '';
    _numeroController.text = user.enderecoNumero ?? '';
    _bairroController.text = user.enderecoBairro ?? '';
    _cidadeController.text = user.enderecoCidade ?? '';
    _estadoController.text = user.enderecoEstado ?? '';
    _complementoController.text = user.enderecoComplemento ?? '';

    // Definir estado selecionado
    _estadoSelecionado = user.enderecoEstado;

    // Carregar cidades se o estado estiver preenchido
    if (_estadoSelecionado != null && _estadoSelecionado!.isNotEmpty) {
      // Definir a cidade que queremos selecionar antes de carregar a lista
      final cidadeDesejada = user.enderecoCidade;
      _cidadeSelecionada = cidadeDesejada;
      _loadCidades(_estadoSelecionado!);
    }
  }

  // Carrega lista de estados
  Future<void> _loadEstados() async {
    setState(() {
      _isEstadosLoading = true;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;
      final result = await authService.getEstados(
        clientService.currentConfig.clientType,
      );

      if (result.success && result.data != null) {
        setState(() {
          _estados = result.data!;
          _isEstadosLoading = false;
        });
      } else {
        setState(() {
          _isEstadosLoading = false;
        });
        _showErrorToast(result.error ?? 'Erro ao carregar estados');
      }
    } catch (e) {
      setState(() {
        _isEstadosLoading = false;
      });
      _showErrorToast('Erro inesperado ao carregar estados: $e');
    }
  }

  // Carrega lista de cidades por estado
  Future<void> _loadCidades(String siglaEstado) async {
    // Salvar cidade selecionada atual para validar depois
    final cidadeAtual = _cidadeSelecionada;

    setState(() {
      _isCidadesLoading = true;
      _cidades = [];
      _cidadeSelecionada = null;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;
      final result = await authService.getCidades(
        clientService.currentConfig.clientType,
        siglaEstado,
      );

      if (result.success && result.data != null) {
        // Remover cidades duplicadas pelo nome (case-insensitive)
        final cidadesUnicas = <String, Map<String, dynamic>>{};
        for (var cidade in result.data!) {
          final nome = cidade['nome'] as String;
          final chaveNormalizada = nome.trim().toUpperCase();
          // Mantém apenas a primeira ocorrência de cada nome (normalizado)
          if (!cidadesUnicas.containsKey(chaveNormalizada)) {
            cidadesUnicas[chaveNormalizada] = cidade;
          }
        }

        final cidadesList = cidadesUnicas.values.toList();

        // Validar se a cidade atual ainda existe na lista
        String? cidadeValidada;
        if (cidadeAtual != null && cidadeAtual.isNotEmpty) {
          // Normalizar para maiúsculo para comparação
          final cidadeAtualUpper = cidadeAtual.trim().toUpperCase();

          final cidadeEncontrada = cidadesList.firstWhere(
            (cidade) =>
                cidade['nome'].toString().trim().toUpperCase() ==
                cidadeAtualUpper,
            orElse: () => {},
          );

          if (cidadeEncontrada.isNotEmpty) {
            // Usar o nome original da API (mantém a formatação correta)
            cidadeValidada = cidadeEncontrada['nome'];
          }
        }

        setState(() {
          _cidades = cidadesList;
          _cidadeSelecionada = cidadeValidada;
          _isCidadesLoading = false;
        });
      } else {
        setState(() {
          _isCidadesLoading = false;
        });
        _showErrorToast(result.error ?? 'Erro ao carregar cidades');
      }
    } catch (e) {
      setState(() {
        _isCidadesLoading = false;
      });
      _showErrorToast('Erro inesperado ao carregar cidades: $e');
    }
  }

  // Converte data de DD/MM/AAAA para YYYY-MM-DD
  String? _convertDateToISOFormat(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      // Remove qualquer formatação e verifica se tem 10 caracteres (DD/MM/AAAA)
      if (dateString.length != 10) return null;

      final parts = dateString.split('/');
      if (parts.length != 3) return null;

      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2];

      // Validação básica
      final dayInt = int.tryParse(day);
      final monthInt = int.tryParse(month);
      final yearInt = int.tryParse(year);

      if (dayInt == null || monthInt == null || yearInt == null) return null;
      if (dayInt < 1 ||
          dayInt > 31 ||
          monthInt < 1 ||
          monthInt > 12 ||
          yearInt < 1900) {
        return null;
      }

      return '$year-$month-$day';
    } catch (e) {
      return null;
    }
  }

  // Formata data de string ISO para exibição no campo de texto
  String _formatDateFromString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString; // Retorna a string original se não conseguir fazer o parse
    }
  }

  // Formata o tipo de documento para exibição
  String _getFormattedTipoDocumento(String? tipoDocumento) {
    if (tipoDocumento == null || tipoDocumento.isEmpty) return 'Não informado';

    switch (tipoDocumento.toLowerCase()) {
      case 'cpf':
        return 'CPF';
      case 'passaporte':
        return 'Passaporte';
      default:
        return tipoDocumento.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alterar Dados'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
          ? const Center(
              child: Text(
                'Erro ao carregar dados do usuário',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 24),
                        _buildPersonalDataSection(),
                        const SizedBox(height: 24),
                        _buildContactSection(),
                        const SizedBox(height: 24),
                        _buildAddressSection(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.edit, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Editar Meus Dados',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Atualize suas informações pessoais',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDataSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Dados Pessoais',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nome (não editável)
            _buildReadOnlyField(
              'Nome Completo',
              _currentUser?.nome ?? '',
              Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // Tipo de Documento (não editável)
            _buildReadOnlyField(
              'Tipo de Documento',
              _getFormattedTipoDocumento(_currentUser?.tipoDocumento),
              Icons.description_outlined,
            ),
            const SizedBox(height: 16),

            // Documento (não editável)
            _buildReadOnlyField(
              'Documento',
              _currentUser?.cpfCnpj ?? '',
              Icons.credit_card,
            ),
            const SizedBox(height: 16),

            // RG (editável)
            TextFormField(
              controller: _rgController,
              decoration: const InputDecoration(
                labelText: 'RG',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 5) {
                  return 'RG deve ter pelo menos 5 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Data de Nascimento (editável)
            TextFormField(
              controller: _dataNascimentoController,
              decoration: const InputDecoration(
                labelText: 'Data de Nascimento',
                hintText: 'DD/MM/AAAA',
                prefixIcon: Icon(Icons.cake_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
                _DateInputFormatter(),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length != 10) {
                    return 'Data deve estar no formato DD/MM/AAAA';
                  }
                  // Validação básica de data
                  final parts = value.split('/');
                  if (parts.length != 3) return 'Formato inválido';

                  final day = int.tryParse(parts[0]);
                  final month = int.tryParse(parts[1]);
                  final year = int.tryParse(parts[2]);

                  if (day == null || month == null || year == null) {
                    return 'Data inválida';
                  }

                  if (day < 1 ||
                      day > 31 ||
                      month < 1 ||
                      month > 12 ||
                      year < 1900) {
                    return 'Data inválida';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Estado Civil (dropdown)
            DropdownButtonFormField<String>(
              initialValue: _estadoCivilSelecionado,
              decoration: const InputDecoration(
                labelText: 'Estado Civil',
                prefixIcon: Icon(Icons.favorite_outline),
                border: OutlineInputBorder(),
              ),
              items: _estadosCivis.map((estado) {
                return DropdownMenuItem(
                  value: estado,
                  child: Text(_formatEstadoCivil(estado)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _estadoCivilSelecionado = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Gênero (dropdown)
            DropdownButtonFormField<String>(
              initialValue: _generoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Gênero',
                prefixIcon: Icon(Icons.people_outline),
                border: OutlineInputBorder(),
              ),
              items: _generos.map((genero) {
                return DropdownMenuItem(
                  value: genero,
                  child: Text(_formatGenero(genero)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _generoSelecionado = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_phone,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contato',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email é obrigatório';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Telefone
            TextFormField(
              controller: _telefoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone Principal',
                hintText: 'Apenas números (máx. 11 dígitos)',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Telefone é obrigatório';
                }
                if (value.length < 10) {
                  return 'Telefone deve ter pelo menos 10 dígitos';
                }
                if (value.length > 11) {
                  return 'Telefone deve ter no máximo 11 dígitos';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Endereço',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // CEP
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cepController,
                    decoration: const InputDecoration(
                      labelText: 'CEP',
                      hintText: '00000-000',
                      prefixIcon: Icon(Icons.location_searching),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      _CepInputFormatter(),
                    ],
                    onChanged: (value) {
                      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (cleaned.length == 8) {
                        _searchCep(cleaned);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (_isCepLoading)
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: () {
                      final cep = _cepController.text.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      if (cep.length == 8) {
                        _searchCep(cep);
                      }
                    },
                    icon: const Icon(Icons.search),
                    tooltip: 'Buscar CEP',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Logradouro
            TextFormField(
              controller: _logradouroController,
              decoration: const InputDecoration(
                labelText: 'Logradouro',
                prefixIcon: Icon(Icons.route_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Número e Complemento
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _numeroController,
                    decoration: const InputDecoration(
                      labelText: 'Número',
                      prefixIcon: Icon(Icons.tag_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _complementoController,
                    decoration: const InputDecoration(
                      labelText: 'Complemento',
                      prefixIcon: Icon(Icons.apartment_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bairro
            TextFormField(
              controller: _bairroController,
              decoration: const InputDecoration(
                labelText: 'Bairro',
                prefixIcon: Icon(Icons.map_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Estado
            DropdownButtonFormField<String>(
              initialValue: _estadoSelecionado,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Estado',
                prefixIcon: Icon(Icons.public_outlined),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Selecione o estado'),
              items: _estados.map((estado) {
                return DropdownMenuItem<String>(
                  value: estado['sigla'],
                  child: Text(
                    '${estado['sigla']} - ${estado['nome']}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _isEstadosLoading
                  ? null
                  : (value) {
                      setState(() {
                        _estadoSelecionado = value;
                        _estadoController.text = value ?? '';
                        _cidadeSelecionada = null;
                        _cidadeController.clear();
                      });
                      if (value != null) {
                        _loadCidades(value);
                      }
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Estado é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Cidade
            DropdownButtonFormField<String>(
              initialValue: _cidadeSelecionada,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Cidade',
                prefixIcon: const Icon(Icons.location_city_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: _isCidadesLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              hint: const Text('Selecione a cidade'),
              items: _cidades.map((cidade) {
                return DropdownMenuItem<String>(
                  value: cidade['nome'],
                  child: Text(cidade['nome'], overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (_isCidadesLoading || _estadoSelecionado == null)
                  ? null
                  : (value) {
                      setState(() {
                        _cidadeSelecionada = value;
                        _cidadeController.text = value ?? '';
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Cidade é obrigatória';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Não informado' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveData,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Salvar Alterações',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _searchCep(String cep) async {
    setState(() {
      _isCepLoading = true;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;
      final result = await authService.searchCep(
        cep,
        clientService.currentConfig.clientType,
      );

      if (result.success && result.data != null) {
        final data = result.data!;
        setState(() {
          _logradouroController.text = data['logradouro'] ?? '';
          _bairroController.text = data['bairro'] ?? '';

          // Definir o estado primeiro
          final estado = data['estado'] ?? '';
          _estadoSelecionado = estado;
          _estadoController.text = estado;

          // Limpar cidade e carregar as cidades do estado
          _cidadeSelecionada = null;
          _cidadeController.clear();
        });

        // Carregar cidades se o estado foi encontrado
        if (_estadoSelecionado != null && _estadoSelecionado!.isNotEmpty) {
          await _loadCidades(_estadoSelecionado!);

          // Após carregar as cidades, tentar selecionar a cidade do CEP
          final cidade = data['cidade'] ?? '';
          if (cidade.isNotEmpty) {
            setState(() {
              _cidadeSelecionada = cidade;
              _cidadeController.text = cidade;
            });
          }
        }
      } else {
        _showErrorToast(result.error ?? 'CEP não encontrado');
      }
    } catch (e) {
      _showErrorToast('Erro ao buscar CEP');
    } finally {
      setState(() {
        _isCepLoading = false;
      });
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;

      // Montar dados para envio - incluir _id obrigatoriamente
      final userData = <String, dynamic>{
        '_id': _currentUser?.id ?? '', // ID obrigatório
      };

      // Dados pessoais editáveis
      if (_rgController.text.isNotEmpty) {
        userData['rg'] = _rgController.text.trim();
      }

      if (_dataNascimentoController.text.isNotEmpty) {
        final convertedDate = _convertDateToISOFormat(
          _dataNascimentoController.text.trim(),
        );
        if (convertedDate != null) {
          userData['data_nascimento'] = convertedDate;
        }
      }

      if (_estadoCivilSelecionado != null) {
        userData['estado_civil'] = _estadoCivilSelecionado;
      }

      if (_generoSelecionado != null) {
        userData['genero'] = _generoSelecionado;
      }

      // Dados de contato
      userData['email'] = _emailController.text.trim();
      userData['numero_telefone_acesso'] = _telefoneController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      // Endereço - usar campos diretos conforme especificado
      if (_cepController.text.isNotEmpty) {
        userData['endereco_cep'] = _cepController.text.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );
      }
      if (_logradouroController.text.isNotEmpty) {
        userData['endereco_logradouro'] = _logradouroController.text.trim();
      }
      if (_numeroController.text.isNotEmpty) {
        userData['endereco_numero'] = _numeroController.text.trim();
      }
      if (_bairroController.text.isNotEmpty) {
        userData['endereco_bairro'] = _bairroController.text.trim();
      }
      if (_cidadeController.text.isNotEmpty) {
        userData['endereco_cidade'] = _cidadeController.text.trim();
      }
      if (_estadoController.text.isNotEmpty) {
        userData['endereco_estado'] = _estadoController.text
            .trim()
            .toUpperCase();
      }
      if (_complementoController.text.isNotEmpty) {
        userData['endereco_complemento'] = _complementoController.text.trim();
      }

      try {
        final result = await authService.updatePersonalData(
          clientService.currentConfig.clientType,
          userData,
        );

        if (result.success) {
          // Verificar se o widget ainda está montado antes de usar o context
          if (mounted) {
            // Voltar uma tela
            Navigator.of(context).pop(true);
            // Mostrar alerta de sucesso agradecendo
            _showSuccessToast('Obrigado por atualizar seus dados!');
          }
        } else {
          _showErrorToast(result.error ?? 'Erro ao atualizar dados');
        }
      } catch (apiError) {
        _showErrorToast('Erro de API: $apiError');
      }
    } catch (e) {
      _showErrorToast('Erro inesperado ao atualizar dados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatEstadoCivil(String estadoCivil) {
    switch (estadoCivil) {
      case 'SOLTEIRO':
        return 'Solteiro(a)';
      case 'CASADO':
        return 'Casado(a)';
      case 'DIVORCIADO':
        return 'Divorciado(a)';
      case 'VIUVO':
        return 'Viúvo(a)';
      case 'UNIAO ESTAVEL':
        return 'União Estável';
      case 'SEPARADO':
        return 'Separado(a)';
      default:
        return estadoCivil;
    }
  }

  String _formatGenero(String genero) {
    switch (genero) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMININO':
        return 'Feminino';
      case 'NAO BINARIO':
        return 'Não Binário';
      case 'PREFIRO NAO INFORMAR':
        return 'Prefiro Não Informar';
      default:
        return genero;
    }
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Formatador para data
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // Se o usuário está apagando, permitir
    if (newText.length < oldText.length) {
      return newValue;
    }

    // Remover caracteres não numéricos
    final digits = newText.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 8) {
      return oldValue;
    }

    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 1 || i == 3) {
        buffer.write('/');
      }
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formatador para telefone
// Formatador para CEP
class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.length > 8) {
      return oldValue;
    }

    final buffer = StringBuffer();

    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      if (i == 4 && i < newText.length - 1) {
        buffer.write('-');
      }
    }

    final String formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
