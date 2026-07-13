class CarteirinhasResumoModel {
  final int qtdEmissao;
  final int qtdRenovacao;
  final List<ParticipanteCarteirinhaModel> participantes;
  final VendaCarteirinhaPendenteModel? vendaPendente;
  final double valorEmissao;
  final double valorRenovacao;

  CarteirinhasResumoModel({
    required this.qtdEmissao,
    required this.qtdRenovacao,
    required this.participantes,
    this.vendaPendente,
    required this.valorEmissao,
    required this.valorRenovacao,
  });

  factory CarteirinhasResumoModel.fromJson(Map<String, dynamic> json) {
    return CarteirinhasResumoModel(
      qtdEmissao: json['qtd_emissao'] ?? 0,
      qtdRenovacao: json['qtd_renovacao'] ?? 0,
      participantes: (json['participantes'] as List<dynamic>? ?? [])
          .map((e) => ParticipanteCarteirinhaModel.fromJson(e))
          .toList(),
      vendaPendente: json['venda_pendente'] != null
          ? VendaCarteirinhaPendenteModel.fromJson(json['venda_pendente'])
          : null,
      valorEmissao: (json['valor_emissao'] as num?)?.toDouble() ?? 0,
      valorRenovacao: (json['valor_renovacao'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get temPendencia =>
      vendaPendente != null &&
      !vendaPendente!.pago &&
      vendaPendente!.statusPagamento != 'QUITADO';
  bool get temElegiveis => qtdEmissao > 0 || qtdRenovacao > 0;
}

class ParticipanteCarteirinhaModel {
  final String clienteId;
  final String clienteNome;
  final String dependencia;
  final String participanteHash;
  final String statusCarteirinha;
  final String? opDisponivel;
  final bool selecionavel;
  final double? valorUnitario;

  ParticipanteCarteirinhaModel({
    required this.clienteId,
    required this.clienteNome,
    required this.dependencia,
    required this.participanteHash,
    required this.statusCarteirinha,
    this.opDisponivel,
    required this.selecionavel,
    this.valorUnitario,
  });

  factory ParticipanteCarteirinhaModel.fromJson(Map<String, dynamic> json) {
    return ParticipanteCarteirinhaModel(
      clienteId: json['cliente_id']?.toString() ?? '',
      clienteNome: json['cliente_nome'] ?? '',
      dependencia: json['dependencia'] ?? '',
      participanteHash: json['hash_code'] ?? '',
      statusCarteirinha: json['status_carteirinha'] ?? '',
      opDisponivel: json['op_disponivel'],
      selecionavel: json['selecionavel'] == true,
      valorUnitario: (json['valor_unitario'] as num?)?.toDouble(),
    );
  }

  String get tipoLabel => dependencia == 'TITULAR' ? 'Titular' : 'Dependente';

  String get opDisponivelLabel =>
      opDisponivel == 'RENOVACAO' ? 'Renovação' : 'Emissão';
}

class VendaCarteirinhaPendenteModel {
  final String vendaId;
  final String codigo;
  final double valorTotal;
  final String statusPagamento;
  final bool pago;
  final bool expirado;
  final DateTime? expiraEm;
  final PixCarteirinhaModel? pix;
  final List<ItemVendaCarteirinhaModel> itens;

  VendaCarteirinhaPendenteModel({
    required this.vendaId,
    required this.codigo,
    required this.valorTotal,
    required this.statusPagamento,
    required this.pago,
    required this.expirado,
    this.expiraEm,
    this.pix,
    this.itens = const [],
  });

  factory VendaCarteirinhaPendenteModel.fromJson(Map<String, dynamic> json) {
    return VendaCarteirinhaPendenteModel(
      vendaId: json['venda_id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      valorTotal: (json['valor_total'] as num?)?.toDouble() ?? 0,
      statusPagamento: json['status_pagamento'] ?? '',
      pago: json['pago'] == true,
      expirado: json['expirado'] == true,
      expiraEm: json['expira_em'] != null
          ? DateTime.tryParse(json['expira_em'].toString())
          : null,
      pix: json['pix'] != null
          ? PixCarteirinhaModel.fromJson(json['pix'])
          : null,
      itens: (json['itens'] as List<dynamic>? ?? [])
          .map((e) => ItemVendaCarteirinhaModel.fromJson(e))
          .toList(),
    );
  }
}

class ItemVendaCarteirinhaModel {
  final String clienteNome;
  final String dependencia;
  final String operacao;
  final double? valor;

  ItemVendaCarteirinhaModel({
    required this.clienteNome,
    required this.dependencia,
    required this.operacao,
    this.valor,
  });

  factory ItemVendaCarteirinhaModel.fromJson(Map<String, dynamic> json) {
    return ItemVendaCarteirinhaModel(
      clienteNome: json['cliente_nome'] ?? '',
      dependencia: json['dependencia'] ?? '',
      operacao: json['operacao'] ?? '',
      valor: (json['valor'] as num?)?.toDouble(),
    );
  }

  String get operacaoLabel =>
      operacao == 'RENOVACAO' ? 'Renovação' : 'Emissão';

  String get dependenciaLabel =>
      dependencia == 'TITULAR' ? 'Titular' : 'Dependente';
}

class PixCarteirinhaModel {
  final String txid;
  final String status;
  final String? pixCopiaECola;

  PixCarteirinhaModel({
    required this.txid,
    required this.status,
    this.pixCopiaECola,
  });

  factory PixCarteirinhaModel.fromJson(Map<String, dynamic> json) {
    return PixCarteirinhaModel(
      txid: json['txid'] ?? '',
      status: json['status'] ?? '',
      pixCopiaECola: json['pix_copia_e_cola'],
    );
  }
}

class VerificarCarteirinhaVendaResult {
  final bool pago;
  final bool cancelada;
  final bool carteirinhasEmitidas;
  final VendaCarteirinhaPendenteModel? venda;

  VerificarCarteirinhaVendaResult({
    required this.pago,
    required this.cancelada,
    required this.carteirinhasEmitidas,
    this.venda,
  });

  factory VerificarCarteirinhaVendaResult.fromJson(Map<String, dynamic> json) {
    return VerificarCarteirinhaVendaResult(
      pago: json['pago'] == true,
      cancelada: json['cancelada'] == true,
      carteirinhasEmitidas: json['carteirinhas_emitidas'] == true,
      venda: json['venda'] != null
          ? VendaCarteirinhaPendenteModel.fromJson(json['venda'])
          : null,
    );
  }
}
