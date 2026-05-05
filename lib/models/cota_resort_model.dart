class CotaResortModel {
  final String id;
  final int idContrato;
  final DateTime dataCadastro;
  final String numeroContrato;
  final String statusContrato;
  final double valorNegociado;
  final UsuarioCota? usuario;
  final List<ParcelaModel>? parcelas;

  CotaResortModel({
    required this.id,
    required this.idContrato,
    required this.dataCadastro,
    required this.numeroContrato,
    required this.statusContrato,
    required this.valorNegociado,
    this.usuario,
    this.parcelas,
  });

  factory CotaResortModel.fromJson(Map<String, dynamic> json) {
    return CotaResortModel(
      id: json['_id'] ?? '',
      idContrato: json['idcontrato'] ?? 0,
      dataCadastro: json['datacadastro'] != null
          ? DateTime.parse(json['datacadastro'])
          : DateTime.now(),
      numeroContrato: json['numerocontrato'] ?? '',
      statusContrato: json['statuscontrato'] ?? '',
      valorNegociado: (json['valornegociado'] ?? 0).toDouble(),
      usuario: json['usuario'] != null
          ? UsuarioCota.fromJson(json['usuario'])
          : null,
      parcelas: json['parcelas'] != null
          ? (json['parcelas'] as List)
                .map((p) => ParcelaModel.fromJson(p))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'idcontrato': idContrato,
      'datacadastro': dataCadastro.toIso8601String(),
      'numerocontrato': numeroContrato,
      'statuscontrato': statusContrato,
      'valornegociado': valorNegociado,
      'usuario': usuario?.toJson(),
      'parcelas': parcelas?.map((p) => p.toJson()).toList(),
    };
  }

  bool get isAtivo => statusContrato.toUpperCase() == 'ATIVO';
}

class UsuarioCota {
  final String id;
  final String nome;
  final String cpfCnpj;
  final String email;
  final List<String> telefones;
  final String numeroTelefoneAcesso;

  UsuarioCota({
    required this.id,
    required this.nome,
    required this.cpfCnpj,
    required this.email,
    required this.telefones,
    required this.numeroTelefoneAcesso,
  });

  factory UsuarioCota.fromJson(Map<String, dynamic> json) {
    return UsuarioCota(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      email: json['email'] ?? '',
      telefones: json['telefones'] != null
          ? List<String>.from(json['telefones'])
          : [],
      numeroTelefoneAcesso: json['numero_telefone_acesso'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nome': nome,
      'cpf_cnpj': cpfCnpj,
      'email': email,
      'telefones': telefones,
      'numero_telefone_acesso': numeroTelefoneAcesso,
    };
  }
}

class ParcelaModel {
  final int identificador;
  final int nroParcela;
  final String? numeroDocumento;
  final String dataVencimento;
  final String tipoParcelaDescricao;
  final String meioPagamentoCodigo;
  final String? linhaDigitavelBoleto;
  final String? codigoBarrasBoleto;
  final bool existeBoletoGerado;
  final bool pago;
  final String statusParcela;
  final double valorParcela;
  final String? dataPagamento;
  final String? dataLiquidacao;
  final double valorAcrescimo;
  final double valorLiquido;
  final double valorJurosCalculado;
  final double valorTotalComJuros;

  ParcelaModel({
    required this.identificador,
    required this.nroParcela,
    this.numeroDocumento,
    required this.dataVencimento,
    required this.tipoParcelaDescricao,
    required this.meioPagamentoCodigo,
    this.linhaDigitavelBoleto,
    this.codigoBarrasBoleto,
    required this.existeBoletoGerado,
    required this.pago,
    required this.statusParcela,
    required this.valorParcela,
    this.dataPagamento,
    this.dataLiquidacao,
    required this.valorAcrescimo,
    required this.valorLiquido,
    required this.valorJurosCalculado,
    required this.valorTotalComJuros,
  });

  factory ParcelaModel.fromJson(Map<String, dynamic> json) {
    return ParcelaModel(
      identificador: json['Identificador'] ?? 0,
      nroParcela: json['NroParcela'] ?? 0,
      numeroDocumento: json['NumeroDocumento'],
      dataVencimento: json['DataVencimento'] ?? '',
      tipoParcelaDescricao: json['TipoParcelaDescricao'] ?? '',
      meioPagamentoCodigo: json['MeioPagamentoCodigo'] ?? '',
      linhaDigitavelBoleto: json['LinhaDigitavelBoleto'],
      codigoBarrasBoleto: json['CodigoBarrasBoleto'],
      existeBoletoGerado: json['ExisteBoletoGerado'] ?? false,
      pago: json['Pago'] ?? false,
      statusParcela: json['StatusParcela'] ?? '',
      valorParcela: (json['ValorParcela'] ?? 0).toDouble(),
      dataPagamento: json['DataPagamento'],
      dataLiquidacao: json['DataLiquidacao'],
      valorAcrescimo: (json['ValorAcrescimo'] ?? 0).toDouble(),
      valorLiquido: (json['ValorLiquido'] ?? 0).toDouble(),
      valorJurosCalculado: (json['_valorJurosCalculado'] ?? 0).toDouble(),
      valorTotalComJuros: (json['_valorTotalComJuros'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Identificador': identificador,
      'NroParcela': nroParcela,
      'NumeroDocumento': numeroDocumento,
      'DataVencimento': dataVencimento,
      'TipoParcelaDescricao': tipoParcelaDescricao,
      'MeioPagamentoCodigo': meioPagamentoCodigo,
      'LinhaDigitavelBoleto': linhaDigitavelBoleto,
      'CodigoBarrasBoleto': codigoBarrasBoleto,
      'ExisteBoletoGerado': existeBoletoGerado,
      'Pago': pago,
      'StatusParcela': statusParcela,
      'ValorParcela': valorParcela,
      'DataPagamento': dataPagamento,
      'DataLiquidacao': dataLiquidacao,
      'ValorAcrescimo': valorAcrescimo,
      'ValorLiquido': valorLiquido,
      '_valorJurosCalculado': valorJurosCalculado,
      '_valorTotalComJuros': valorTotalComJuros,
    };
  }

  bool get isVencida {
    if (pago) return false;
    final vencimento = DateTime.parse(dataVencimento);
    return vencimento.isBefore(DateTime.now());
  }

  bool get isAtiva => statusParcela.toUpperCase() == 'ATIVO';
  bool get isBaixada => statusParcela.toUpperCase() == 'BAIXADO';
}
