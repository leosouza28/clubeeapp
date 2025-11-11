import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/calendario_model.dart';
import '../models/reserva_model.dart';
import '../services/client_service.dart';
import '../services/api_service.dart';
import 'reservas_screen.dart';

class NovaReservaScreen extends StatefulWidget {
  final String tituloId;
  final String? tituloNome;

  const NovaReservaScreen({super.key, required this.tituloId, this.tituloNome});

  @override
  State<NovaReservaScreen> createState() => _NovaReservaScreenState();
}

class _NovaReservaScreenState extends State<NovaReservaScreen> {
  // Controle de etapas
  int _currentStep = 0;

  // Estado do calendário
  CalendarioModel? _calendarioData;
  bool _carregandoCalendario = true;
  String? _errCalendario;
  DateTime? _dataSelecionada;
  DateTime _mesSelecionado = DateTime.now();
  final List<int?> _diasDoMes = [];

  // Estado das cortesias
  List<CortesiaDisponivelModel> _cortesias = [];
  bool _carregandoCortesias = false;
  String? _errCortesias;
  CortesiaDisponivelModel? _cortesiaSelecionada;
  int _quantidade = 0; // Quantidade selecionada

  // Estado da confirmação
  bool _aceiteiTermos = false;
  bool _aceiteiRegularidade = false; // Novo checkbox
  bool _enviandoReserva = false;
  String? _errReserva;

  @override
  void initState() {
    super.initState();
    _calcularDiasDoMes();
    _carregarCalendario();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _carregarCalendario() async {
    setState(() {
      _carregandoCalendario = true;
      _errCalendario = null;
    });

    try {
      final client = ClientService.instance;
      final apiService = await ApiService.getInstance();
      final resultado = await apiService.getCalendario(
        client.currentClientType,
      );

      if (resultado.success && resultado.data != null) {
        setState(() {
          _calendarioData = CalendarioModel.fromJson(resultado.data!);
          _carregandoCalendario = false;
        });
      } else {
        setState(() {
          _errCalendario = resultado.error ?? 'Erro ao carregar calendário';
          _carregandoCalendario = false;
        });
      }
    } catch (e) {
      setState(() {
        _errCalendario = 'Erro de conexão: $e';
        _carregandoCalendario = false;
      });
    }
  }

  void _calcularDiasDoMes() {
    final primeiroDia = DateTime(
      _mesSelecionado.year,
      _mesSelecionado.month,
      1,
    );
    final ultimoDia = DateTime(
      _mesSelecionado.year,
      _mesSelecionado.month + 1,
      0,
    );
    final diasNoMes = ultimoDia.day;
    final diaDaSemana = primeiroDia.weekday % 7; // 0 = domingo

    _diasDoMes.clear();

    // Adicionar espaços vazios no início
    for (int i = 0; i < diaDaSemana; i++) {
      _diasDoMes.add(null);
    }

    // Adicionar os dias do mês
    for (int dia = 1; dia <= diasNoMes; dia++) {
      _diasDoMes.add(dia);
    }
  }

  void _mesAnterior() {
    setState(() {
      _mesSelecionado = DateTime(
        _mesSelecionado.year,
        _mesSelecionado.month - 1,
      );
      _calcularDiasDoMes();
    });
  }

  void _proximoMes() {
    setState(() {
      _mesSelecionado = DateTime(
        _mesSelecionado.year,
        _mesSelecionado.month + 1,
      );
      _calcularDiasDoMes();
    });
  }

  String _formatarMes(DateTime data) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${meses[data.month - 1]} ${data.year}';
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  void _selecionarData(DateTime data) {
    setState(() {
      _dataSelecionada = data;
    });
  }

  Future<void> _carregarCortesias() async {
    if (_dataSelecionada == null) {
      setState(() {
        _errCortesias = 'Data não selecionada';
        _carregandoCortesias = false;
      });
      return;
    }

    setState(() {
      _carregandoCortesias = true;
      _errCortesias = null;
      _cortesias.clear();
      _cortesiaSelecionada = null;
      _quantidade = 0; // Reset quantidade
    });

    try {
      final client = ClientService.instance;
      final apiService = await ApiService.getInstance();
      final dataFormatada =
          '${_dataSelecionada!.year}-${_dataSelecionada!.month.toString().padLeft(2, '0')}-${_dataSelecionada!.day.toString().padLeft(2, '0')}';

      final resultado = await apiService.getCortesiasDisponiveis(
        client.currentClientType,
        widget.tituloId,
        dataFormatada,
      );

      if (resultado.success && resultado.data != null) {
        setState(() {
          _cortesias = resultado.data!
              .map((item) => CortesiaDisponivelModel.fromJson(item))
              .toList();
          _carregandoCortesias = false;
        });
      } else {
        setState(() {
          _errCortesias = resultado.error ?? 'Erro ao carregar cortesias';
          _carregandoCortesias = false;
        });
      }
    } catch (e) {
      setState(() {
        _errCortesias = 'Erro de conexão: $e';
        _carregandoCortesias = false;
      });
    }
  }

  Future<void> _criarReserva() async {
    if (_dataSelecionada == null || _cortesiaSelecionada == null) return;

    setState(() {
      _enviandoReserva = true;
      _errReserva = null;
    });

    try {
      final client = ClientService.instance;
      final apiService = await ApiService.getInstance();

      final dataFormatada =
          '${_dataSelecionada!.year}-${_dataSelecionada!.month.toString().padLeft(2, '0')}-${_dataSelecionada!.day.toString().padLeft(2, '0')}';

      // Converte o tipo da cortesia para o formato da API
      String tipoParaAPI = _cortesiaSelecionada!.tipo;
      if (tipoParaAPI == 'CONTRATO') {
        tipoParaAPI = 'CONTRATO';
      }

      final request = ReservaRequest(
        concordo: _aceiteiTermos,
        quantidade: _quantidade,
        retirar: 'VISITANTE_LINK',
        data: dataFormatada,
        isFormattedData: true,
        tituloId: widget.tituloId,
        tipoCortesia: tipoParaAPI,
        versaoCortesia: 2,
      );

      final resultado = await apiService.criarReserva(
        client.currentClientType,
        request.toJson(),
      );

      if (resultado.success) {
        // Sucesso - extrair hash se disponível
        final responseData = resultado.data;
        String? hashCriado;

        if (responseData != null && responseData['hash'] != null) {
          hashCriado = responseData['hash'] as String;
          if (kDebugMode) {
            print('🎯 Hash da reserva criada: $hashCriado');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva criada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar para a tela de reservas e passar o hash para abrir automaticamente
          Navigator.of(context).pop(); // Fechar esta tela
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ReservasScreen(
                tituloId: widget.tituloId,
                tituloNome: widget.tituloNome ?? 'Reservas',
                hashToOpen: hashCriado,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errReserva = resultado.error ?? 'Erro ao criar reserva';
          _enviandoReserva = false;
        });
      }
    } catch (e) {
      setState(() {
        _errReserva = 'Erro de conexão: $e';
        _enviandoReserva = false;
      });
    }
  }

  void _proximaEtapa() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });

      if (_currentStep == 1) {
        _carregarCortesias();
      }
    } else {
      // Última etapa - criar reserva
      _criarReserva();
    }
  }

  void _etapaAnterior() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Reserva'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Indicador de etapas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Calendário'),
                Expanded(child: _buildStepLine(0)),
                _buildStepIndicator(1, 'Cortesia'),
                Expanded(child: _buildStepLine(1)),
                _buildStepIndicator(2, 'Confirmação'),
              ],
            ),
          ),

          // Conteúdo das etapas
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildCalendarioStep(),
                _buildCortesiasStep(),
                _buildConfirmacaoStep(),
              ],
            ),
          ),

          // Botões de navegação
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _etapaAnterior,
                      child: const Text('Voltar'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _podeAvancar() ? _proximaEtapa : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _currentStep == 2 ? 'Confirmar Reserva' : 'Próximo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = step <= _currentStep;
    final isCurrent = step == _currentStep;

    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isActive
              ? Colors.blue.shade600
              : Colors.grey.shade300,
          child: Text(
            (step + 1).toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Colors.blue.shade600 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = step < _currentStep;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? Colors.blue.shade600 : Colors.grey.shade300,
    );
  }

  Widget _buildCalendarioStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione uma data:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_carregandoCalendario)
            const Center(child: CircularProgressIndicator())
          else if (_errCalendario != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errCalendario!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header do mês
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _mesAnterior,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            _formatarMes(_mesSelecionado),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _proximoMes,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  // Dias da semana
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children:
                          ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab']
                              .map(
                                (dia) => Expanded(
                                  child: Text(
                                    dia,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  // Grid dos dias
                  SizedBox(
                    height:
                        320, // Aumentado de 240 para 320 para mostrar mais fileiras
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                      itemCount: _diasDoMes.length,
                      itemBuilder: (context, index) {
                        final dia = _diasDoMes[index];
                        if (dia == null) {
                          return Container(); // Dia vazio
                        }

                        final data = DateTime(
                          _mesSelecionado.year,
                          _mesSelecionado.month,
                          dia,
                        );
                        final diasCalendario =
                            _calendarioData?.diasFuncionamento ?? [];
                        final diaInfo = diasCalendario.firstWhere(
                          (d) {
                            final diaDateTime = d.dateTime;
                            return diaDateTime != null &&
                                diaDateTime.day == dia &&
                                diaDateTime.month == _mesSelecionado.month &&
                                diaDateTime.year == _mesSelecionado.year;
                          },
                          orElse: () => DiaFuncionamentoModel(
                            data: data.toIso8601String(),
                            dataString: _formatarData(data),
                            estado: 'Fechado',
                            horaInicio: '',
                            horaFim: '',
                          ),
                        );

                        final isSelected =
                            _dataSelecionada?.day == dia &&
                            _dataSelecionada?.month == _mesSelecionado.month &&
                            _dataSelecionada?.year == _mesSelecionado.year;

                        Color? backgroundColor;
                        Color? textColor;

                        if (isSelected) {
                          backgroundColor = Colors.blue;
                          textColor = Colors.white;
                        } else if (diaInfo.podeReservar) {
                          backgroundColor = Colors.green.shade100;
                          textColor = Colors.green.shade800;
                        } else {
                          backgroundColor = Colors.grey.shade200;
                          textColor = Colors.grey.shade600;
                        }

                        return GestureDetector(
                          onTap: diaInfo.podeReservar
                              ? () => _selecionarData(data)
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                dia.toString(),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (_dataSelecionada != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Data selecionada: ${_formatarData(_dataSelecionada!)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCortesiasStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione o tipo de cortesia:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_carregandoCortesias)
            const Center(child: CircularProgressIndicator())
          else if (_errCortesias != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errCortesias!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_cortesias.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nenhuma cortesia disponível para esta data.',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_cortesias.map(
              (cortesia) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<CortesiaDisponivelModel>(
                  title: Text(cortesia.tipoDisplay),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disponível: ${cortesia.quantidade}',
                        style: TextStyle(
                          color: cortesia.quantidade > 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  value: cortesia,
                  groupValue: _cortesiaSelecionada,
                  onChanged: cortesia.quantidade > 0
                      ? (value) {
                          setState(() {
                            _cortesiaSelecionada = value;
                            _quantidade =
                                0; // Reset quantidade ao trocar cortesia
                          });
                        }
                      : null,
                ),
              ),
            )),

          // Controle de quantidade
          if (_cortesiaSelecionada != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Selecione a quantidade:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Quantidade:', style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    // Botão de diminuir
                    IconButton(
                      onPressed: _quantidade > 0
                          ? () => setState(() => _quantidade--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                      color: _quantidade > 0 ? Colors.red : Colors.grey,
                    ),
                    // Display da quantidade
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _quantidade.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Botão de aumentar
                    IconButton(
                      onPressed: _quantidade < _cortesiaSelecionada!.quantidade
                          ? () => setState(() => _quantidade++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                      color: _quantidade < _cortesiaSelecionada!.quantidade
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            if (_quantidade > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      _quantidade == 1
                          ? 'Selecionado: 1 cortesia'
                          : 'Selecionado: $_quantidade cortesias',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmacaoStep() {
    // Se ainda não temos os dados necessários, mostra loading
    if (_dataSelecionada == null || _cortesiaSelecionada == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparando confirmação...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirme sua reserva:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo da Reserva',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Data: ${_formatarData(_dataSelecionada!)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Tipo da Reserva: ${_cortesiaSelecionada!.tipoDisplay}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Quantidade: $_quantidade ${_quantidade == 1 ? 'pessoa' : 'pessoas'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Informações importantes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Informações Importantes',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Será gerado um link que você irá compartilhar com o seu convidado. Lembrando que para menores de 18 anos, será necessário informar os dados de um adulto responsável no link.',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Checkboxes obrigatórios
          CheckboxListTile(
            title: const Text(
              'Aceito os termos de uso e política de privacidade',
            ),
            subtitle: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Abrindo política de privacidade...'),
                  ),
                );
                // Abre o link da política de privacidade
                // Usar um pacote como url_launcher para abrir o link
                final clientConfig = ClientService.instance.currentConfig;
                final linkPrivacidade = clientConfig.linkPrivacidade;
                launchUrl(Uri.parse(linkPrivacidade));
              },
              child: Text(
                'Clique aqui para ler a política de privacidade',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  decoration: TextDecoration.underline,
                  fontSize: 12,
                ),
              ),
            ),
            value: _aceiteiTermos,
            onChanged: (value) =>
                setState(() => _aceiteiTermos = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),

          CheckboxListTile(
            title: const Text(
              'Tenho consciência que para fazer uso das minhas cortesias devo estar regular com o meu plano',
            ),
            value: _aceiteiRegularidade,
            onChanged: (value) =>
                setState(() => _aceiteiRegularidade = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_errReserva != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errReserva!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_enviandoReserva) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  bool _podeAvancar() {
    switch (_currentStep) {
      case 0:
        return _dataSelecionada != null;
      case 1:
        return _cortesiaSelecionada != null && _quantidade > 0;
      case 2:
        return _aceiteiTermos &&
            _aceiteiRegularidade &&
            !_enviandoReserva &&
            _quantidade > 0;
      default:
        return false;
    }
  }
}
