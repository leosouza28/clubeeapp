class CobrancasResponseModel {
  final String id;
  final String tituloSerieHash;
  final String titulo;
  final String codSerie;
  final String nomeSerie;
  final String situacao;
  final bool bloqueado;
  final PendenciasFinanceirasModel pendenciasFinanceiras;
  final List<CobrancaModel> lista;

  CobrancasResponseModel({
    required this.id,
    required this.tituloSerieHash,
    required this.titulo,
    required this.codSerie,
    required this.nomeSerie,
    required this.situacao,
    required this.bloqueado,
    required this.pendenciasFinanceiras,
    required this.lista,
  });

  factory CobrancasResponseModel.fromJson(Map<String, dynamic> json) {
    return CobrancasResponseModel(
      id: json['_id'] ?? '',
      tituloSerieHash: json['titulo_serie_hash'] ?? '',
      titulo: json['titulo'] ?? '',
      codSerie: json['cod_serie'] ?? '',
      nomeSerie: json['nome_serie'] ?? '',
      situacao: json['situacao'] ?? '',
      bloqueado: json['bloqueado'] ?? false,
      pendenciasFinanceiras: PendenciasFinanceirasModel.fromJson(
        json['pendencias_financeiras'] ?? {},
      ),
      lista:
          (json['lista'] as List<dynamic>?)
              ?.map((e) => CobrancaModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CobrancaModel {
  final String id;
  final String? labelParcela;
  final String descricao;
  final DateTime emissao;
  final DateTime vencimento;
  final String situacao;
  final double valor;
  final double juros;
  final double desconto;
  final double total;
  final bool paymentAppAvailable;
  final bool? pixCopiaColaAvailable;
  final String? pixCopiaColaValue;
  final bool? boletoLinhaDigitavelAvailable;
  final String? boletoLinhaDigitavelValue;
  final bool? boletoUrlPdfAvailable;
  final String? boletoUrlPdfValue;

  CobrancaModel({
    required this.id,
    this.labelParcela,
    required this.descricao,
    required this.emissao,
    required this.vencimento,
    required this.situacao,
    required this.valor,
    required this.juros,
    required this.desconto,
    required this.total,
    required this.paymentAppAvailable,
    this.pixCopiaColaAvailable,
    this.pixCopiaColaValue,
    this.boletoLinhaDigitavelAvailable,
    this.boletoLinhaDigitavelValue,
    this.boletoUrlPdfAvailable,
    this.boletoUrlPdfValue,
  });

  factory CobrancaModel.fromJson(Map<String, dynamic> json) {
    return CobrancaModel(
      id: json['_id'] ?? '',
      labelParcela: json['label_parcela'],
      descricao: json['descricao'] ?? '',
      emissao: DateTime.parse(json['emissao']),
      vencimento: DateTime.parse(json['vencimento']),
      situacao: json['situacao'] ?? '',
      valor: (json['valor'] ?? 0).toDouble(),
      juros: (json['juros'] ?? 0).toDouble(),
      desconto: (json['desconto'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentAppAvailable: json['payment_app_available'] ?? false,
      pixCopiaColaAvailable: json['pix_copia_cola_available'],
      pixCopiaColaValue: json['pix_copia_cola_value'],
      boletoLinhaDigitavelAvailable: json['boleto_linha_digitavel_available'],
      boletoLinhaDigitavelValue: json['boleto_linha_digitavel_value'],
      boletoUrlPdfAvailable: json['boleto_url_pdf_available'],
      boletoUrlPdfValue: json['boleto_url_pdf_value'],
    );
  }

  // Helpers para situação
  bool get isPago => situacao.toUpperCase() == 'PAGO';
  bool get isNormal => situacao.toUpperCase() == 'NORMAL';
  bool get isEmAtraso => situacao.toUpperCase() == 'EM ATRASO';

  // Helpers para pagamento
  bool get temPixDisponivel =>
      paymentAppAvailable &&
      (pixCopiaColaAvailable ?? false) &&
      (pixCopiaColaValue?.isNotEmpty ?? false);

  bool get temBoletoDigitavelDisponivel =>
      paymentAppAvailable &&
      (boletoLinhaDigitavelAvailable ?? false) &&
      (boletoLinhaDigitavelValue?.isNotEmpty ?? false);

  bool get temBoletoPdfDisponivel =>
      (boletoUrlPdfAvailable ?? false) &&
      (boletoUrlPdfValue?.isNotEmpty ?? false);
}

class PendenciasFinanceirasModel {
  final int qtdPendencias;
  final double valorPendencias;
  final String statusPendencia;

  PendenciasFinanceirasModel({
    required this.qtdPendencias,
    required this.valorPendencias,
    required this.statusPendencia,
  });

  factory PendenciasFinanceirasModel.fromJson(Map<String, dynamic> json) {
    return PendenciasFinanceirasModel(
      qtdPendencias: json['qtd_pendencias'] ?? 0,
      valorPendencias: (json['valor_pendencias'] ?? 0).toDouble(),
      statusPendencia: json['status_pendencia'] ?? 'EM DIA',
    );
  }

  bool get isInadimplente => statusPendencia.toUpperCase() == 'INADIMPLENTE';
  bool get isEmDia => statusPendencia.toUpperCase() == 'EM DIA';
}
