class GuiaCobrancaResortModel {
  final String id;
  final String codigo;
  final DateTime data;
  final String origem;
  final String formaPagamento;
  final String gateway;
  final PixResortModel? pix;
  final List<CobrancaResortModel> cobrancas;
  final int quantidadeCobrancas;
  final String statusBaixaCobrancas;
  final CotaResortInfoModel cota;
  final UsuarioInfoModel? usuario;
  final UsuarioInfoModel? criadoPor;
  final PagamentoConcluido? pagamentoConcluidoPor;
  final String status;
  final double valorBruto;
  final double valorJuros;
  final double valorDesconto;
  final double valorTotal;
  final ClubeInfoModel? clube;
  final DateTime createdAt;
  final DateTime updatedAt;

  GuiaCobrancaResortModel({
    required this.id,
    required this.codigo,
    required this.data,
    required this.origem,
    required this.formaPagamento,
    required this.gateway,
    this.pix,
    required this.cobrancas,
    required this.quantidadeCobrancas,
    required this.statusBaixaCobrancas,
    required this.cota,
    this.usuario,
    this.criadoPor,
    this.pagamentoConcluidoPor,
    required this.status,
    required this.valorBruto,
    required this.valorJuros,
    required this.valorDesconto,
    required this.valorTotal,
    this.clube,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuiaCobrancaResortModel.fromJson(Map<String, dynamic> json) {
    return GuiaCobrancaResortModel(
      id: json['_id'] ?? '',
      codigo: json['codigo'] ?? '',
      data: json['data'] != null ? DateTime.parse(json['data']) : DateTime.now(),
      origem: json['origem'] ?? '',
      formaPagamento: json['forma_pagamento'] ?? '',
      gateway: json['gateway'] ?? '',
      pix: json['pix'] != null ? PixResortModel.fromJson(json['pix']) : null,
      cobrancas: (json['cobrancas'] as List<dynamic>?)
              ?.map((c) => CobrancaResortModel.fromJson(c))
              .toList() ??
          [],
      quantidadeCobrancas: json['quantidade_cobrancas'] ?? 0,
      statusBaixaCobrancas: json['status_baixa_cobrancas'] ?? '',
      cota: CotaResortInfoModel.fromJson(json['cota'] ?? {}),
      usuario: json['usuario'] != null
          ? UsuarioInfoModel.fromJson(json['usuario'])
          : null,
      criadoPor: json['criado_por'] != null
          ? UsuarioInfoModel.fromJson(json['criado_por'])
          : null,
      pagamentoConcluidoPor: json['pagamento_concluido_por'] != null
          ? PagamentoConcluido.fromJson(json['pagamento_concluido_por'])
          : null,
      status: json['status'] ?? '',
      valorBruto: (json['valor_bruto'] ?? 0).toDouble(),
      valorJuros: (json['valor_juros'] ?? 0).toDouble(),
      valorDesconto: (json['valor_desconto'] ?? 0).toDouble(),
      valorTotal: (json['valor_total'] ?? 0).toDouble(),
      clube: json['clube'] != null
          ? ClubeInfoModel.fromJson(json['clube'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
}

class PixResortModel {
  final String txid;
  final String status;
  final DateTime expiraEm;
  final DateTime criadoEm;
  final String pixCopiaECola;

  PixResortModel({
    required this.txid,
    required this.status,
    required this.expiraEm,
    required this.criadoEm,
    required this.pixCopiaECola,
  });

  factory PixResortModel.fromJson(Map<String, dynamic> json) {
    return PixResortModel(
      txid: json['txid'] ?? '',
      status: json['status'] ?? '',
      expiraEm: json['expira_em'] != null
          ? DateTime.parse(json['expira_em'])
          : DateTime.now(),
      criadoEm: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'])
          : DateTime.now(),
      pixCopiaECola: json['pix_copia_e_cola'] ?? '',
    );
  }
}

class CobrancaResortModel {
  final int identificador;
  final int idContrato;
  final int nroParcela;
  final String meioPagamentoTexto;
  final String meioPagamentoDescricao;
  final DateTime dataVencimento;
  final bool paga;
  final double valorParcela;
  final bool existeBoletoGerado;
  final String statusParcela;
  final String linhaDigitavelBoleto;
  final String codigoBarrasBoleto;
  final double valorJurosCalculado;
  final double valorTotalComJuros;
  final bool baixaTSE;

  CobrancaResortModel({
    required this.identificador,
    required this.idContrato,
    required this.nroParcela,
    required this.meioPagamentoTexto,
    required this.meioPagamentoDescricao,
    required this.dataVencimento,
    required this.paga,
    required this.valorParcela,
    required this.existeBoletoGerado,
    required this.statusParcela,
    required this.linhaDigitavelBoleto,
    required this.codigoBarrasBoleto,
    required this.valorJurosCalculado,
    required this.valorTotalComJuros,
    required this.baixaTSE,
  });

  factory CobrancaResortModel.fromJson(Map<String, dynamic> json) {
    return CobrancaResortModel(
      identificador: json['Identificador'] ?? 0,
      idContrato: json['IdContrato'] ?? 0,
      nroParcela: json['NroParcela'] ?? 0,
      meioPagamentoTexto: json['MeioPagamentoTexto'] ?? '',
      meioPagamentoDescricao: json['MeioPagamentoDescricao'] ?? '',
      dataVencimento: json['DataVencimento'] != null
          ? DateTime.parse(json['DataVencimento'])
          : DateTime.now(),
      paga: json['Paga'] ?? false,
      valorParcela: (json['ValorParcela'] ?? 0).toDouble(),
      existeBoletoGerado: json['ExisteBoletoGerado'] ?? false,
      statusParcela: json['StatusParcela'] ?? '',
      linhaDigitavelBoleto: json['LinhaDigitavelBoleto'] ?? '',
      codigoBarrasBoleto: json['CodigoBarrasBoleto'] ?? '',
      valorJurosCalculado: (json['_valorJurosCalculado'] ?? 0).toDouble(),
      valorTotalComJuros: (json['_valorTotalComJuros'] ?? 0).toDouble(),
      baixaTSE: json['_baixa_TSE'] ?? false,
    );
  }
}

class CotaResortInfoModel {
  final String id;
  final int idContrato;
  final String numeroContrato;
  final String statusContrato;

  CotaResortInfoModel({
    required this.id,
    required this.idContrato,
    required this.numeroContrato,
    required this.statusContrato,
  });

  factory CotaResortInfoModel.fromJson(Map<String, dynamic> json) {
    return CotaResortInfoModel(
      id: json['_id'] ?? '',
      idContrato: json['idcontrato'] ?? 0,
      numeroContrato: json['numerocontrato'] ?? '',
      statusContrato: json['statuscontrato'] ?? '',
    );
  }
}

class UsuarioInfoModel {
  final String id;
  final String nome;
  final String email;
  final String cpfCnpj;
  final String numeroTelefoneAcesso;

  UsuarioInfoModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpfCnpj,
    required this.numeroTelefoneAcesso,
  });

  factory UsuarioInfoModel.fromJson(Map<String, dynamic> json) {
    return UsuarioInfoModel(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      numeroTelefoneAcesso: json['numero_telefone_acesso'] ?? '',
    );
  }
}

class PagamentoConcluido {
  final DateTime dataHora;
  final UsuarioInfoModel usuario;

  PagamentoConcluido({
    required this.dataHora,
    required this.usuario,
  });

  factory PagamentoConcluido.fromJson(Map<String, dynamic> json) {
    return PagamentoConcluido(
      dataHora: json['data_hora'] != null
          ? DateTime.parse(json['data_hora'])
          : DateTime.now(),
      usuario: UsuarioInfoModel.fromJson(json['usuario'] ?? {}),
    );
  }
}

class ClubeInfoModel {
  final String id;
  final String nome;

  ClubeInfoModel({
    required this.id,
    required this.nome,
  });

  factory ClubeInfoModel.fromJson(Map<String, dynamic> json) {
    return ClubeInfoModel(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
    );
  }
}
