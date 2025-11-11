class TituloDetailsModel {
  final String id;
  final String codSerie;
  final String titulo;
  final DateTime assinatura;
  final bool bloqueado;
  final List<DependenteModel> dependentes;
  final String nomeSerie;
  final UsuarioTituloDetails usuario;
  final DateTime vencimento;
  final String tituloSerieHash;
  final List<PacoteCortesiaModel> pacoteCortesias;
  final String situacao;
  final VendedorModel? vendedor;
  final bool requerAceiteUso;
  final bool mostraAceite;
  final String? termosDeUso;
  final TitularModel titular;
  final PendenciasFinanceirasModel? pendenciasFinanceiras;
  final ContratoDigitalAssinaturaCliente? contratoDigitalAssinaturaCliente;
  final String? contratoDigitalStatus;
  final String? contratoDigitalLinkAssinado;

  TituloDetailsModel({
    required this.id,
    required this.codSerie,
    required this.titulo,
    required this.assinatura,
    required this.bloqueado,
    required this.dependentes,
    required this.nomeSerie,
    required this.usuario,
    required this.vencimento,
    required this.tituloSerieHash,
    required this.pacoteCortesias,
    required this.situacao,
    this.vendedor,
    required this.requerAceiteUso,
    required this.mostraAceite,
    this.termosDeUso,
    required this.titular,
    this.pendenciasFinanceiras,
    this.contratoDigitalAssinaturaCliente,
    this.contratoDigitalStatus,
    this.contratoDigitalLinkAssinado,
  });

  factory TituloDetailsModel.fromJson(Map<String, dynamic> json) {
    return TituloDetailsModel(
      id: json['_id'] ?? '',
      codSerie: json['cod_serie'] ?? '',
      titulo: json['titulo'] ?? '',
      assinatura: DateTime.parse(json['assinatura']),
      bloqueado: json['bloqueado'] ?? false,
      dependentes:
          (json['dependentes'] as List<dynamic>?)
              ?.map((e) => DependenteModel.fromJson(e))
              .toList() ??
          [],
      nomeSerie: json['nome_serie'] ?? '',
      usuario: UsuarioTituloDetails.fromJson(json['usuario'] ?? {}),
      vencimento: DateTime.parse(json['vencimento']),
      tituloSerieHash: json['titulo_serie_hash'] ?? '',
      pacoteCortesias:
          (json['pacote_cortesias'] as List<dynamic>?)
              ?.map((e) => PacoteCortesiaModel.fromJson(e))
              .toList() ??
          [],
      situacao: json['situacao'] ?? '',
      vendedor: json['vendedor'] != null
          ? VendedorModel.fromJson(json['vendedor'])
          : null,
      requerAceiteUso: json['requer_aceite_uso'] ?? false,
      mostraAceite: json['mostra_aceite'] ?? false,
      termosDeUso: json['termos_de_uso'],
      titular: TitularModel.fromJson(json['titular'] ?? {}),
      pendenciasFinanceiras: json['pendencias_financeiras'] != null
          ? PendenciasFinanceirasModel.fromJson(json['pendencias_financeiras'])
          : null,
      contratoDigitalAssinaturaCliente:
          json['contrato_digital_assinatura_cliente'] != null
          ? ContratoDigitalAssinaturaCliente.fromJson(
              json['contrato_digital_assinatura_cliente'],
            )
          : null,
      contratoDigitalStatus: json['contrato_digital_status'],
      contratoDigitalLinkAssinado: json['contrato_digital_link_assinado'],
    );
  }

  // Propriedades derivadas
  bool get requerAtencao {
    return situacao.toUpperCase() == 'PENDENTE' ||
        (situacao.toUpperCase() == 'ATIVO' && bloqueado);
  }

  String get statusDisplay {
    if (bloqueado) return 'BLOQUEADO';
    return situacao.toUpperCase();
  }

  int get totalCortesiasDisponiveis {
    return pacoteCortesias
        .where((p) => p.situacao.toUpperCase() == 'ATIVADO')
        .fold(0, (total, p) => total + p.quantidade);
  }

  List<DependenteModel> get dependentesAtivos {
    return dependentes.where((d) => !d.livre).toList();
  }

  List<DependenteModel> get dependentesLivres {
    return dependentes.where((d) => d.livre).toList();
  }
}

class DependenteModel {
  final String id;
  final String hash;
  final String nome;
  final DateTime? dataNasc;
  final String parentesco;
  final String tipoDocumento;
  final String genero;
  final DateTime? cadastradoEm;
  final DateTime? ultimaCarteirinhaEm;
  final String cpf;
  final String telefone;
  final String email;
  final String tags;
  final bool livre;
  final bool? isUsuarioCadastrado;
  final String foto;
  final bool isMenorIdade;
  final UsuarioAcaoModel? adicionadoPor;
  final UsuarioAcaoModel? alteradoPor;
  final String? carteirinhaHash;
  final bool carteirinhaEmitida;
  final bool carteirinhaVencida;
  final DateTime? carteirinhaDataValidade;
  final DateTime? carteirinhaDataEmissao;
  final String? carteirinhaUrl;
  final String? carteirinhaFoto;

  DependenteModel({
    required this.id,
    required this.hash,
    required this.nome,
    this.dataNasc,
    required this.parentesco,
    required this.tipoDocumento,
    required this.genero,
    this.cadastradoEm,
    this.ultimaCarteirinhaEm,
    required this.cpf,
    required this.telefone,
    required this.email,
    required this.tags,
    required this.livre,
    this.isUsuarioCadastrado,
    required this.foto,
    required this.isMenorIdade,
    this.adicionadoPor,
    this.alteradoPor,
    this.carteirinhaHash,
    required this.carteirinhaEmitida,
    required this.carteirinhaVencida,
    this.carteirinhaDataValidade,
    this.carteirinhaDataEmissao,
    this.carteirinhaUrl,
    this.carteirinhaFoto,
  });

  factory DependenteModel.fromJson(Map<String, dynamic> json) {
    return DependenteModel(
      id: json['_id'] ?? '',
      hash: json['hash'] ?? '',
      nome: json['nome'] ?? '',
      dataNasc: json['data_nasc'] != null
          ? DateTime.parse(json['data_nasc'])
          : null,
      parentesco: json['parentesco'] ?? '',
      tipoDocumento: json['tipo_documento'] ?? '',
      genero: json['genero'] ?? '',
      cadastradoEm: json['cadastrado_em'] != null
          ? DateTime.tryParse(
              json['cadastrado_em'].toString().replaceAll(' ', 'T'),
            )
          : null,
      ultimaCarteirinhaEm: json['ultima_carteirinha_em'] != null
          ? DateTime.parse(json['ultima_carteirinha_em'])
          : null,
      cpf: json['cpf'] ?? '',
      telefone: json['telefone'] ?? '',
      email: json['email'] ?? '',
      tags: json['tags'] ?? '',
      livre: json['livre'] ?? false,
      isUsuarioCadastrado: json['is_usuario_cadastrado'] is bool
          ? json['is_usuario_cadastrado']
          : null,
      foto: json['foto'] ?? '',
      isMenorIdade: json['is_menor_idade'] ?? false,
      adicionadoPor: json['adicionado_por'] != null
          ? UsuarioAcaoModel.fromJson(json['adicionado_por'])
          : null,
      alteradoPor: json['alterado_por'] != null
          ? UsuarioAcaoModel.fromJson(json['alterado_por'])
          : null,
      carteirinhaHash: json['carteirinha_hash'],
      carteirinhaEmitida: json['carteirinha_emitida'] ?? false,
      carteirinhaVencida: json['carteirinha_vencida'] ?? false,
      carteirinhaDataValidade: json['carteirinha_data_validade'] != null
          ? DateTime.parse(json['carteirinha_data_validade'])
          : null,
      carteirinhaDataEmissao: json['carteirinha_data_emissao'] != null
          ? DateTime.parse(json['carteirinha_data_emissao'])
          : null,
      carteirinhaUrl: json['carteirinha_url'],
      carteirinhaFoto: json['carteirinha_foto'],
    );
  }

  int get idade {
    if (dataNasc == null) return 0;
    final now = DateTime.now();
    int age = now.year - dataNasc!.year;
    if (now.month < dataNasc!.month ||
        (now.month == dataNasc!.month && now.day < dataNasc!.day)) {
      age--;
    }
    return age;
  }

  bool get temCarteirinhaValida {
    return carteirinhaEmitida && !carteirinhaVencida;
  }
}

class UsuarioTituloDetails {
  final String id;
  final String cpfCnpj;
  final String nome;
  final String email;
  final String numeroTelefoneAcesso;
  final List<String> telefones;

  UsuarioTituloDetails({
    required this.id,
    required this.cpfCnpj,
    required this.nome,
    required this.email,
    required this.numeroTelefoneAcesso,
    required this.telefones,
  });

  factory UsuarioTituloDetails.fromJson(Map<String, dynamic> json) {
    return UsuarioTituloDetails(
      id: json['_id'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      numeroTelefoneAcesso: json['numero_telefone_acesso'] ?? '',
      telefones: List<String>.from(json['telefones'] ?? []),
    );
  }
}

class PacoteCortesiaModel {
  final String descricao;
  final int quantidade;
  final String situacao;
  final String periodo;
  final DateTime dataFinal;

  PacoteCortesiaModel({
    required this.descricao,
    required this.quantidade,
    required this.situacao,
    required this.periodo,
    required this.dataFinal,
  });

  factory PacoteCortesiaModel.fromJson(Map<String, dynamic> json) {
    return PacoteCortesiaModel(
      descricao: json['descricao'] ?? '',
      quantidade: json['quantidade'] ?? 0,
      situacao: json['situacao'] ?? '',
      periodo: json['periodo'] ?? '',
      dataFinal: DateTime.parse(json['data_final']),
    );
  }
}

class VendedorModel {
  final String id;
  final String nome;
  final String cpfCnpj;
  final String email;
  final String numeroTelefoneAcesso;

  VendedorModel({
    required this.id,
    required this.nome,
    required this.cpfCnpj,
    required this.email,
    required this.numeroTelefoneAcesso,
  });

  factory VendedorModel.fromJson(Map<String, dynamic> json) {
    return VendedorModel(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      email: json['email'] ?? '',
      numeroTelefoneAcesso: json['numero_telefone_acesso'] ?? '',
    );
  }
}

class TitularModel {
  final String id;
  final String nome;
  final DateTime dataNasc;
  final int idade;
  final String genero;
  final String hash;
  final String? carteirinhaHash;
  final bool carteirinhaEmitida;
  final bool carteirinhaVencida;
  final DateTime? carteirinhaDataValidade;
  final DateTime? carteirinhaDataEmissao;
  final String? carteirinhaUrl;
  final String? carteirinhaFoto;
  final bool titularCanAddFoto;

  TitularModel({
    required this.id,
    required this.nome,
    required this.dataNasc,
    required this.idade,
    required this.genero,
    required this.hash,
    this.carteirinhaHash,
    required this.carteirinhaEmitida,
    required this.carteirinhaVencida,
    this.carteirinhaDataValidade,
    this.carteirinhaDataEmissao,
    this.carteirinhaUrl,
    this.carteirinhaFoto,
    required this.titularCanAddFoto,
  });

  // Getter para verificar se tem carteirinha válida
  bool get temCarteirinhaValida => carteirinhaEmitida && !carteirinhaVencida;

  factory TitularModel.fromJson(Map<String, dynamic> json) {
    return TitularModel(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      dataNasc: json['data_nasc'] != null
          ? DateTime.parse(json['data_nasc'])
          : DateTime.now(),
      idade: json['idade'] ?? 0,
      genero: json['genero'] ?? '',
      hash: json['hash'] ?? '',
      carteirinhaHash: json['carteirinha_hash'],
      carteirinhaEmitida: json['carteirinha_emitida'] ?? false,
      carteirinhaVencida: json['carteirinha_vencida'] ?? false,
      carteirinhaDataValidade: json['carteirinha_data_validade'] != null
          ? DateTime.parse(json['carteirinha_data_validade'])
          : null,
      carteirinhaDataEmissao: json['carteirinha_data_emissao'] != null
          ? DateTime.parse(json['carteirinha_data_emissao'])
          : null,
      carteirinhaUrl: json['carteirinha_url'],
      carteirinhaFoto: json['carteirinha_foto'],
      titularCanAddFoto: json['titular_can_add_foto'] ?? false,
    );
  }
}

class UsuarioAcaoModel {
  final DateTime dataHora;
  final UsuarioSimpleModel usuario;

  UsuarioAcaoModel({required this.dataHora, required this.usuario});

  factory UsuarioAcaoModel.fromJson(Map<String, dynamic> json) {
    return UsuarioAcaoModel(
      dataHora: DateTime.parse(
        json['data_hora'].toString().replaceAll(' ', 'T'),
      ),
      usuario: UsuarioSimpleModel.fromJson(json['usuario'] ?? {}),
    );
  }
}

class UsuarioSimpleModel {
  final String id;
  final String nome;

  UsuarioSimpleModel({required this.id, required this.nome});

  factory UsuarioSimpleModel.fromJson(Map<String, dynamic> json) {
    return UsuarioSimpleModel(id: json['_id'] ?? '', nome: json['nome'] ?? '');
  }
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

class ContratoDigitalAssinaturaCliente {
  final String? link;
  final String? status;

  ContratoDigitalAssinaturaCliente({this.link, this.status});

  factory ContratoDigitalAssinaturaCliente.fromJson(Map<String, dynamic> json) {
    return ContratoDigitalAssinaturaCliente(
      link: json['link'],
      status: json['status'],
    );
  }

  bool get isPendente => status?.toUpperCase() == 'PENDENTE';
}
