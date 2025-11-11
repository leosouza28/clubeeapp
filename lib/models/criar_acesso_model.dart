/// Modelo para as opções disponíveis de criação de acesso
class CriarAcessoOpcoesModel {
  final String usuarioId;
  final String usuarioNome;
  final List<OpcaoEnvioCodigoModel> opcoesDisponiveis;

  CriarAcessoOpcoesModel({
    required this.usuarioId,
    required this.usuarioNome,
    required this.opcoesDisponiveis,
  });

  factory CriarAcessoOpcoesModel.fromJson(Map<String, dynamic> json) {
    return CriarAcessoOpcoesModel(
      usuarioId: json['usuario_id'] as String,
      usuarioNome: json['usuario_nome'] as String,
      opcoesDisponiveis: (json['opcoes_disponiveis'] as List)
          .map((opcao) => OpcaoEnvioCodigoModel.fromJson(opcao))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'usuario_nome': usuarioNome,
      'opcoes_disponiveis': opcoesDisponiveis.map((o) => o.toJson()).toList(),
    };
  }
}

/// Modelo para cada opção de envio de código
class OpcaoEnvioCodigoModel {
  final String tipo;
  final String descricao;
  final String value;

  OpcaoEnvioCodigoModel({
    required this.tipo,
    required this.descricao,
    required this.value,
  });

  factory OpcaoEnvioCodigoModel.fromJson(Map<String, dynamic> json) {
    return OpcaoEnvioCodigoModel(
      tipo: json['tipo'] as String,
      descricao: json['descricao'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'tipo': tipo, 'descricao': descricao, 'value': value};
  }

  // Helper para obter o valor mascarado para exibição
  String get valorMascarado {
    if (tipo.contains('EMAIL')) {
      // Mascarar email: l***@gmail.com
      final parts = value.split('@');
      if (parts.length == 2) {
        final localPart = parts[0];
        final domain = parts[1];
        final maskedLocal = localPart.length > 2
            ? '${localPart[0]}***${localPart[localPart.length - 1]}'
            : localPart;
        return '$maskedLocal@$domain';
      }
      return value;
    } else if (tipo.contains('TELEFONE')) {
      // Mascarar telefone: (91) *****-5923
      if (value.length >= 4) {
        final lastFour = value.substring(value.length - 4);
        return '*****$lastFour';
      }
      return value;
    }
    return value;
  }

  // Helper para obter ícone baseado no tipo
  String get iconeNome {
    if (tipo.contains('EMAIL')) {
      return 'email';
    } else if (tipo.contains('TELEFONE')) {
      return 'phone';
    }
    return 'help';
  }
}

/// Modelo para a resposta de solicitação de código
class SolicitaCodigoResponseModel {
  final String metodo;
  final String message;

  SolicitaCodigoResponseModel({required this.metodo, required this.message});

  factory SolicitaCodigoResponseModel.fromJson(Map<String, dynamic> json) {
    return SolicitaCodigoResponseModel(
      metodo: json['metodo'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'metodo': metodo, 'message': message};
  }
}
