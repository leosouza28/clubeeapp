class CortesiaModel {
  final String id;
  final String hash;
  final DateTime createdAt;
  final DateTime data;
  final String status;
  final String tipoCortesia;
  final String tipoUsuarioRetirada;
  final int totalCortesias;
  final int totalCortesiasRetiradas;
  final String? siteUrl;
  final ClubeModel clube;
  final TituloModel titulo;
  final UsuarioModel usuario;
  final List<ConvidadoModel> convidados;
  final List<RetiradaModel> retiradas;

  const CortesiaModel({
    required this.id,
    required this.hash,
    required this.createdAt,
    required this.data,
    required this.status,
    required this.tipoCortesia,
    required this.tipoUsuarioRetirada,
    required this.totalCortesias,
    required this.totalCortesiasRetiradas,
    this.siteUrl,
    required this.clube,
    required this.titulo,
    required this.usuario,
    required this.convidados,
    required this.retiradas,
  });

  factory CortesiaModel.fromJson(Map<String, dynamic> json) {
    return CortesiaModel(
      id: json['_id'] as String,
      hash: json['hash'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      data: DateTime.parse(json['data'] as String),
      status: json['status'] as String,
      tipoCortesia: json['tipo_cortesia'] as String,
      tipoUsuarioRetirada: json['tipo_usuario_retirada'] as String,
      totalCortesias: json['total_cortesias'] as int,
      totalCortesiasRetiradas: json['total_cortesias_retiradas'] as int,
      siteUrl: json['site_url'] as String?,
      clube: ClubeModel.fromJson(json['clube'] as Map<String, dynamic>),
      titulo: TituloModel.fromJson(json['titulo'] as Map<String, dynamic>),
      usuario: UsuarioModel.fromJson(json['usuario'] as Map<String, dynamic>),
      convidados:
          (json['convidados'] as List?)
              ?.map(
                (item) => ConvidadoModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      retiradas:
          (json['retiradas'] as List?)
              ?.map(
                (item) => RetiradaModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'AGUARDANDO VINCULO':
        return 'Aguardando Vínculo';
      case 'PENDENTE':
        return 'Pendente';
      case 'PARCIALMENTE_RETIRADA':
        return 'Parcialmente Retirada';
      case 'CANCELADA':
        return 'Cancelada';
      case 'RETIRADA':
        return 'Retirada';
      default:
        return status;
    }
  }

  String get tipoCortesiaDisplay {
    switch (tipoCortesia) {
      case 'CONTRATO':
        return 'Day-Use Contratual';
      case 'PROMOCIONAL':
        return 'Cortesia Promocional';
      default:
        return tipoCortesia;
    }
  }

  bool get podeCompartilhar =>
      status == 'AGUARDANDO VINCULO' || status == 'PENDENTE';

  bool get podeCancelar =>
      status == 'AGUARDANDO VINCULO' || status == 'PENDENTE';

  bool get foiRetirada =>
      status == 'RETIRADA' || status == 'PARCIALMENTE_RETIRADA';
}

class ClubeModel {
  final String id;
  final String nome;

  const ClubeModel({required this.id, required this.nome});

  factory ClubeModel.fromJson(Map<String, dynamic> json) {
    return ClubeModel(id: json['_id'] as String, nome: json['nome'] as String);
  }
}

class TituloModel {
  final String id;
  final String tituloSerieHash;
  final String codSerie;
  final String nomeSerie;
  final String titulo;
  final UsuarioModel usuario;

  const TituloModel({
    required this.id,
    required this.tituloSerieHash,
    required this.codSerie,
    required this.nomeSerie,
    required this.titulo,
    required this.usuario,
  });

  factory TituloModel.fromJson(Map<String, dynamic> json) {
    return TituloModel(
      id: json['_id'] as String,
      tituloSerieHash: json['titulo_serie_hash'] as String,
      codSerie: json['cod_serie'] as String,
      nomeSerie: json['nome_serie'] as String,
      titulo: json['titulo'] as String,
      usuario: UsuarioModel.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }
}

class UsuarioModel {
  final String id;
  final String cpfCnpj;
  final String nome;
  final String email;
  final String numeroTelefoneAcesso;

  const UsuarioModel({
    required this.id,
    required this.cpfCnpj,
    required this.nome,
    required this.email,
    required this.numeroTelefoneAcesso,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['_id'] as String,
      cpfCnpj: json['cpf_cnpj'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      numeroTelefoneAcesso: json['numero_telefone_acesso'] as String,
    );
  }
}

class ConvidadoModel {
  final String id;
  final String nome;
  final String cpf;
  final bool isPassport;
  final DateTime dataNascimento;
  final String telefone;
  final bool retirado;
  final DateTime? dataHoraRetirada;
  final PessoaMenorIdadeModel? pessoaMenorIdade;
  final String? qrcodeData;

  const ConvidadoModel({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.isPassport,
    required this.dataNascimento,
    required this.telefone,
    required this.retirado,
    this.dataHoraRetirada,
    this.pessoaMenorIdade,
    this.qrcodeData,
  });

  factory ConvidadoModel.fromJson(Map<String, dynamic> json) {
    return ConvidadoModel(
      id: json['_id'] as String,
      nome: json['nome'] as String,
      cpf: json['cpf'] as String,
      isPassport: json['is_passport'] as bool? ?? false,
      dataNascimento: DateTime.parse(json['data_nascimento'] as String),
      telefone: json['telefone'] as String,
      retirado: json['retirado'] as bool? ?? false,
      dataHoraRetirada: json['data_hora_retirada'] != null
          ? DateTime.parse(json['data_hora_retirada'] as String)
          : null,
      pessoaMenorIdade: json['pessoa_menor_idade'] != null
          ? PessoaMenorIdadeModel.fromJson(
              json['pessoa_menor_idade'] as Map<String, dynamic>,
            )
          : null,
      qrcodeData: json['_qrcode_data'] as String?,
    );
  }
}

class PessoaMenorIdadeModel {
  final String nome;
  final DateTime dataNascimento;

  const PessoaMenorIdadeModel({
    required this.nome,
    required this.dataNascimento,
  });

  factory PessoaMenorIdadeModel.fromJson(Map<String, dynamic> json) {
    return PessoaMenorIdadeModel(
      nome: json['nome'] as String,
      dataNascimento: DateTime.parse(json['data_nascimento'] as String),
    );
  }
}

class RetiradaModel {
  final String id;
  final int quantidade;
  final DateTime dataHora;
  final UsuarioSistemaModel usuarioSistema;

  const RetiradaModel({
    required this.id,
    required this.quantidade,
    required this.dataHora,
    required this.usuarioSistema,
  });

  factory RetiradaModel.fromJson(Map<String, dynamic> json) {
    return RetiradaModel(
      id: json['_id'] as String,
      quantidade: json['quantidade'] as int,
      dataHora: DateTime.parse(json['data_hora'] as String),
      usuarioSistema: UsuarioSistemaModel.fromJson(
        json['usuario_sistema'] as Map<String, dynamic>,
      ),
    );
  }
}

class UsuarioSistemaModel {
  final String id;
  final String cpfCnpj;
  final String nome;
  final String email;

  const UsuarioSistemaModel({
    required this.id,
    required this.cpfCnpj,
    required this.nome,
    required this.email,
  });

  factory UsuarioSistemaModel.fromJson(Map<String, dynamic> json) {
    return UsuarioSistemaModel(
      id: json['_id'] as String,
      cpfCnpj: json['cpf_cnpj'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
    );
  }
}
