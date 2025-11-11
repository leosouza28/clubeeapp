class NegociacaoResponseModel {
  final String id;
  final String codigo;
  final DateTime data;
  final String origem;
  final String formaPagamento;
  final String gateway;
  final PixNegociacaoModel? pix;
  final List<CobrancaNegociacaoModel> cobrancas;
  final TituloNegociacaoModel titulo;
  final UsuarioNegociacaoModel usuario;
  final UsuarioNegociacaoModel criadoPor;
  final String status;
  final double valorBruto;
  final double valorJuros;
  final double valorDesconto;
  final double valorTotal;
  final int quantidadeCobrancas;
  final ClubeNegociacaoModel clube;

  NegociacaoResponseModel({
    required this.id,
    required this.codigo,
    required this.data,
    required this.origem,
    required this.formaPagamento,
    required this.gateway,
    this.pix,
    required this.cobrancas,
    required this.titulo,
    required this.usuario,
    required this.criadoPor,
    required this.status,
    required this.valorBruto,
    required this.valorJuros,
    required this.valorDesconto,
    required this.valorTotal,
    required this.quantidadeCobrancas,
    required this.clube,
  });

  factory NegociacaoResponseModel.fromJson(Map<String, dynamic> json) {
    return NegociacaoResponseModel(
      id: json['_id'] ?? '',
      codigo: json['codigo'] ?? '',
      data: DateTime.parse(json['data']).toLocal(),
      origem: json['origem'] ?? '',
      formaPagamento: json['forma_pagamento'] ?? '',
      gateway: json['gateway'] ?? '',
      pix: json['pix'] != null
          ? PixNegociacaoModel.fromJson(json['pix'])
          : null,
      cobrancas:
          (json['cobrancas'] as List<dynamic>?)
              ?.map((e) => CobrancaNegociacaoModel.fromJson(e))
              .toList() ??
          [],
      titulo: TituloNegociacaoModel.fromJson(json['titulo']),
      usuario: UsuarioNegociacaoModel.fromJson(json['usuario']),
      criadoPor: UsuarioNegociacaoModel.fromJson(json['criado_por']),
      status: json['status'] ?? '',
      valorBruto: (json['valor_bruto'] ?? 0).toDouble(),
      valorJuros: (json['valor_juros'] ?? 0).toDouble(),
      valorDesconto: (json['valor_desconto'] ?? 0).toDouble(),
      valorTotal: (json['valor_total'] ?? 0).toDouble(),
      quantidadeCobrancas: json['quantidade_cobrancas'] ?? 0,
      clube: ClubeNegociacaoModel.fromJson(json['clube']),
    );
  }
}

class PixNegociacaoModel {
  final String txid;
  final String status;
  final DateTime? expiraEm;
  final DateTime? criadoEm;
  final String? pixCopiaECola;
  final List<PixPagamentoModel> pix;

  PixNegociacaoModel({
    required this.txid,
    required this.status,
    this.expiraEm,
    this.criadoEm,
    this.pixCopiaECola,
    required this.pix,
  });

  factory PixNegociacaoModel.fromJson(Map<String, dynamic> json) {
    return PixNegociacaoModel(
      txid: json['txid'] ?? '',
      status: json['status'] ?? '',
      expiraEm: json['expira_em'] != null
          ? DateTime.parse(json['expira_em']).toLocal()
          : null,
      criadoEm: json['criado_em'] != null
          ? DateTime.parse(json['criado_em']).toLocal()
          : null,
      pixCopiaECola: json['pix_copia_e_cola'],
      pix:
          (json['pix'] as List<dynamic>?)
              ?.map((e) => PixPagamentoModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PixPagamentoModel {
  final String endToEndId;
  final String txid;
  final String valor;
  final DateTime horario;
  final PagadorModel pagador;
  final String infoPagador;

  PixPagamentoModel({
    required this.endToEndId,
    required this.txid,
    required this.valor,
    required this.horario,
    required this.pagador,
    required this.infoPagador,
  });

  factory PixPagamentoModel.fromJson(Map<String, dynamic> json) {
    return PixPagamentoModel(
      endToEndId: json['endToEndId'] ?? '',
      txid: json['txid'] ?? '',
      valor: json['valor'] ?? '',
      horario: DateTime.parse(json['horario']).toLocal(),
      pagador: PagadorModel.fromJson(json['pagador']),
      infoPagador: json['infoPagador'] ?? '',
    );
  }
}

class PagadorModel {
  final String? cpf;
  final String? cnpj;
  final String nome;

  PagadorModel({this.cpf, this.cnpj, required this.nome});

  factory PagadorModel.fromJson(Map<String, dynamic> json) {
    return PagadorModel(
      cpf: json['cpf'],
      cnpj: json['cnpj'],
      nome: json['nome'] ?? '',
    );
  }
}

class CobrancaNegociacaoModel {
  final String cobrancaId;
  final String? labelParcela;
  final String descricao;
  final String descricaoPai;
  final int? parcela;
  final int? totalParcelas;
  final double valor;
  final double juros;
  final double desconto;
  final double total;
  final DateTime? emissao;
  final DateTime? vencimento;

  CobrancaNegociacaoModel({
    required this.cobrancaId,
    this.labelParcela,
    required this.descricao,
    required this.descricaoPai,
    this.parcela,
    this.totalParcelas,
    required this.valor,
    required this.juros,
    required this.desconto,
    required this.total,
    this.emissao,
    this.vencimento,
  });

  factory CobrancaNegociacaoModel.fromJson(Map<String, dynamic> json) {
    return CobrancaNegociacaoModel(
      cobrancaId: json['cobranca_id'] ?? '',
      labelParcela: json['label_parcela'],
      descricao: json['descricao'] ?? '',
      descricaoPai: json['descricao_pai'] ?? '',
      parcela: json['parcela'],
      totalParcelas: json['total_parcelas'],
      valor: (json['valor'] ?? 0).toDouble(),
      juros: (json['juros'] ?? 0).toDouble(),
      desconto: (json['desconto'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      emissao: json['emissao'] != null ? DateTime.parse(json['emissao']) : null,
      vencimento: json['vencimento'] != null
          ? DateTime.parse(json['vencimento'])
          : null,
    );
  }
}

class TituloNegociacaoModel {
  final String id;
  final String tituloSerieHash;
  final String titulo;
  final String codSerie;
  final String nomeSerie;

  TituloNegociacaoModel({
    required this.id,
    required this.tituloSerieHash,
    required this.titulo,
    required this.codSerie,
    required this.nomeSerie,
  });

  factory TituloNegociacaoModel.fromJson(Map<String, dynamic> json) {
    return TituloNegociacaoModel(
      id: json['_id'] ?? '',
      tituloSerieHash: json['titulo_serie_hash'] ?? '',
      titulo: json['titulo'] ?? '',
      codSerie: json['cod_serie'] ?? '',
      nomeSerie: json['nome_serie'] ?? '',
    );
  }
}

class UsuarioNegociacaoModel {
  final String id;
  final String nome;
  final String email;
  final String cpfCnpj;
  final String numeroTelefoneAcesso;

  UsuarioNegociacaoModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpfCnpj,
    required this.numeroTelefoneAcesso,
  });

  factory UsuarioNegociacaoModel.fromJson(Map<String, dynamic> json) {
    return UsuarioNegociacaoModel(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      numeroTelefoneAcesso: json['numero_telefone_acesso'] ?? '',
    );
  }
}

class ClubeNegociacaoModel {
  final String id;
  final String nome;

  ClubeNegociacaoModel({required this.id, required this.nome});

  factory ClubeNegociacaoModel.fromJson(Map<String, dynamic> json) {
    return ClubeNegociacaoModel(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
    );
  }
}
