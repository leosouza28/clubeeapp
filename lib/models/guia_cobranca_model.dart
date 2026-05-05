class GuiaCobrancaModel {
  final String id;
  final String codigo;
  final DateTime data;
  final String origem;
  final String formaPagamento;
  final String gateway;
  final PixData? pix;
  final List<CobrancaItem> cobrancas;
  final int quantidadeCobrancas;
  final String statusBaixaCobrancas;
  final CotaInfo cota;
  final UsuarioInfo usuario;
  final UsuarioInfo criadoPor;
  final String status;
  final double valorBruto;
  final double valorJuros;
  final double valorTotal;
  final ClubeInfo clube;
  final DateTime createdAt;
  final DateTime updatedAt;

  GuiaCobrancaModel({
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
    required this.usuario,
    required this.criadoPor,
    required this.status,
    required this.valorBruto,
    required this.valorJuros,
    required this.valorTotal,
    required this.clube,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuiaCobrancaModel.fromJson(Map<String, dynamic> json) {
    return GuiaCobrancaModel(
      id: json['_id'] ?? '',
      codigo: json['codigo'] ?? '',
      data: DateTime.parse(json['data']),
      origem: json['origem'] ?? '',
      formaPagamento: json['forma_pagamento'] ?? '',
      gateway: json['gateway'] ?? '',
      pix: json['pix'] != null ? PixData.fromJson(json['pix']) : null,
      cobrancas:
          (json['cobrancas'] as List?)
              ?.map((e) => CobrancaItem.fromJson(e))
              .toList() ??
          [],
      quantidadeCobrancas: json['quantidade_cobrancas'] ?? 0,
      statusBaixaCobrancas: json['status_baixa_cobrancas'] ?? '',
      cota: CotaInfo.fromJson(json['cota']),
      usuario: UsuarioInfo.fromJson(json['usuario']),
      criadoPor: UsuarioInfo.fromJson(json['criado_por']),
      status: json['status'] ?? '',
      valorBruto: (json['valor_bruto'] ?? 0).toDouble(),
      valorJuros: (json['valor_juros'] ?? 0).toDouble(),
      valorTotal: (json['valor_total'] ?? 0).toDouble(),
      clube: ClubeInfo.fromJson(json['clube']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class PixData {
  final String txid;
  final String status;
  final DateTime expiraEm;
  final DateTime criadoEm;
  final String pixCopiaECola;

  PixData({
    required this.txid,
    required this.status,
    required this.expiraEm,
    required this.criadoEm,
    required this.pixCopiaECola,
  });

  factory PixData.fromJson(Map<String, dynamic> json) {
    return PixData(
      txid: json['txid'] ?? '',
      status: json['status'] ?? '',
      expiraEm: DateTime.parse(json['expira_em']),
      criadoEm: DateTime.parse(json['criado_em']),
      pixCopiaECola: json['pix_copia_e_cola'] ?? '',
    );
  }
}

class CobrancaItem {
  final int identificador;
  final int nroParcela;
  final DateTime dataVencimento;
  final double valorParcela;
  final bool existeBoletoGerado;
  final String statusParcela;
  final String? linhaDigitavelBoleto;
  final String codigoBarrasBoleto;
  final double valorJurosCalculado;
  final double valorTotalComJuros;
  final String id;

  CobrancaItem({
    required this.identificador,
    required this.nroParcela,
    required this.dataVencimento,
    required this.valorParcela,
    required this.existeBoletoGerado,
    required this.statusParcela,
    this.linhaDigitavelBoleto,
    required this.codigoBarrasBoleto,
    required this.valorJurosCalculado,
    required this.valorTotalComJuros,
    required this.id,
  });

  factory CobrancaItem.fromJson(Map<String, dynamic> json) {
    return CobrancaItem(
      identificador: json['Identificador'] ?? 0,
      nroParcela: json['NroParcela'] ?? 0,
      dataVencimento: DateTime.parse(json['DataVencimento']),
      valorParcela: (json['ValorParcela'] ?? 0).toDouble(),
      existeBoletoGerado: json['ExisteBoletoGerado'] ?? false,
      statusParcela: json['StatusParcela'] ?? '',
      linhaDigitavelBoleto: json['LinhaDigitavelBoleto'],
      codigoBarrasBoleto: json['CodigoBarrasBoleto'] ?? '',
      valorJurosCalculado: (json['_valorJurosCalculado'] ?? 0).toDouble(),
      valorTotalComJuros: (json['_valorTotalComJuros'] ?? 0).toDouble(),
      id: json['_id'] ?? '',
    );
  }
}

class CotaInfo {
  final String id;
  final int idcontrato;
  final String numerocontrato;
  final String statuscontrato;

  CotaInfo({
    required this.id,
    required this.idcontrato,
    required this.numerocontrato,
    required this.statuscontrato,
  });

  factory CotaInfo.fromJson(Map<String, dynamic> json) {
    return CotaInfo(
      id: json['_id'] ?? '',
      idcontrato: json['idcontrato'] ?? 0,
      numerocontrato: json['numerocontrato'] ?? '',
      statuscontrato: json['statuscontrato'] ?? '',
    );
  }
}

class UsuarioInfo {
  final String id;
  final String nome;
  final String email;
  final String cpfCnpj;
  final String numeroTelefoneAcesso;

  UsuarioInfo({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpfCnpj,
    required this.numeroTelefoneAcesso,
  });

  factory UsuarioInfo.fromJson(Map<String, dynamic> json) {
    return UsuarioInfo(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      numeroTelefoneAcesso: json['numero_telefone_acesso'] ?? '',
    );
  }
}

class ClubeInfo {
  final String id;
  final String nome;

  ClubeInfo({required this.id, required this.nome});

  factory ClubeInfo.fromJson(Map<String, dynamic> json) {
    return ClubeInfo(id: json['_id'] ?? '', nome: json['nome'] ?? '');
  }
}
