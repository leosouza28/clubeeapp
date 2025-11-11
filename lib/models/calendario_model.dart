class CalendarioModel {
  final String initialDate;
  final List<DiaFuncionamentoModel> diasFuncionamento;
  final String maxDate;

  CalendarioModel({
    required this.initialDate,
    required this.diasFuncionamento,
    required this.maxDate,
  });

  factory CalendarioModel.fromJson(Map<String, dynamic> json) {
    return CalendarioModel(
      initialDate: json['initial_date'] ?? '',
      diasFuncionamento:
          (json['dias_funcionamento'] as List<dynamic>?)
              ?.map((item) => DiaFuncionamentoModel.fromJson(item))
              .toList() ??
          [],
      maxDate: json['max_date'] ?? '',
    );
  }
}

class DiaFuncionamentoModel {
  final String data;
  final String dataString;
  final String estado;
  final String horaInicio;
  final String horaFim;

  DiaFuncionamentoModel({
    required this.data,
    required this.dataString,
    required this.estado,
    required this.horaInicio,
    required this.horaFim,
  });

  factory DiaFuncionamentoModel.fromJson(Map<String, dynamic> json) {
    return DiaFuncionamentoModel(
      data: json['data'] ?? '',
      dataString: json['data_string'] ?? '',
      estado: json['estado'] ?? '',
      horaInicio: json['hora_inicio'] ?? '',
      horaFim: json['hora_fim'] ?? '',
    );
  }

  bool get isAberto => estado == 'Aberto';
  bool get isAbrira => estado == 'Abrirá';
  bool get isFechado => estado == 'Fechado';
  bool get isAbriraEmBreve => estado == 'Abrirá em breve';

  bool get podeReservar => isAberto || isAbrira;

  DateTime? get dateTime {
    try {
      return data.isNotEmpty ? DateTime.parse(data) : null;
    } catch (e) {
      return null;
    }
  }
}
