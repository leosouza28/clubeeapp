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
  final bool? controleHorario;
  final String? horarioLimite;
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
    this.controleHorario,
    this.horarioLimite,
    required this.clube,
    required this.titulo,
    required this.usuario,
    required this.convidados,
    required this.retiradas,
  });

  factory CortesiaModel.fromJson(Map<String, dynamic> json) {
    var currentField = '<inicializacao>';
    try {
      // print('    🔸 Parsing campo: _id');
      currentField = '_id';
      final id = json['_id'] as String;

      // print('    🔸 Parsing campo: hash');
      currentField = 'hash';
      final hash = json['hash'] as String;

      // print('    🔸 Parsing campo: created_at');
      currentField = 'created_at';
      final createdAt = DateTime.parse(json['created_at'] as String);

      // print('    🔸 Parsing campo: data');
      currentField = 'data';
      final data = DateTime.parse(json['data'] as String);

      // print('    🔸 Parsing campo: status');
      currentField = 'status';
      final status = json['status'] as String;

      // print('    🔸 Parsing campo: tipo_cortesia');
      currentField = 'tipo_cortesia';
      final tipoCortesia = json['tipo_cortesia'] as String;

      // print('    🔸 Parsing campo: tipo_usuario_retirada');
      currentField = 'tipo_usuario_retirada';
      final tipoUsuarioRetirada = json['tipo_usuario_retirada'] as String;

      // print('    🔸 Parsing campo: total_cortesias');
      currentField = 'total_cortesias';
      final totalCortesias = json['total_cortesias'] as int;

      // print('    🔸 Parsing campo: total_cortesias_retiradas');
      currentField = 'total_cortesias_retiradas';
      final totalCortesiasRetiradas = json['total_cortesias_retiradas'] as int;

      // print('    🔸 Parsing campo: site_url');
      currentField = 'site_url';
      final siteUrl = json['site_url'] as String?;

      // print('    🔸 Parsing campo: controle_horario');
      currentField = 'controle_horario';
      final controleHorario = json['controle_horario'] as bool?;

      // print('    🔸 Parsing campo: horario_limite');
      currentField = 'horario_limite';
      final horarioLimite = json['horario_limite'] as String?;

      // print('    🔸 Parsing objeto: clube');
      currentField = 'clube';
      final clube = ClubeModel.fromJson(json['clube'] as Map<String, dynamic>);

      // print('    🔸 Parsing objeto: titulo');
      currentField = 'titulo';
      final titulo = TituloModel.fromJson(
        json['titulo'] as Map<String, dynamic>,
      );

      // print('    🔸 Parsing objeto: usuario');
      currentField = 'usuario';
      final usuario = UsuarioModel.fromJson(
        json['usuario'] as Map<String, dynamic>,
      );

      // print('    🔸 Parsing lista: convidados');
      currentField = 'convidados';
      final convidados =
          (json['convidados'] as List?)
              ?.map(
                (item) => ConvidadoModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [];

      // print('    🔸 Parsing lista: retiradas');
      currentField = 'retiradas';
      final retiradas =
          (json['retiradas'] as List?)
              ?.map(
                (item) => RetiradaModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [];

      // print('    🔸 Criando instância CortesiaModel');
      return CortesiaModel(
        id: id,
        hash: hash,
        createdAt: createdAt,
        data: data,
        status: status,
        tipoCortesia: tipoCortesia,
        tipoUsuarioRetirada: tipoUsuarioRetirada,
        totalCortesias: totalCortesias,
        totalCortesiasRetiradas: totalCortesiasRetiradas,
        siteUrl: siteUrl,
        controleHorario: controleHorario,
        horarioLimite: horarioLimite,
        clube: clube,
        titulo: titulo,
        usuario: usuario,
        convidados: convidados,
        retiradas: retiradas,
      );
    } catch (e, stackTrace) {
      print('    ❌ ERRO no CortesiaModel.fromJson (campo: $currentField): $e');
      print(
        '    Stack: ${stackTrace.toString().split('\n').take(2).join('\n')}',
      );
      throw FormatException(
        'CortesiaModel.fromJson falhou no campo "$currentField": $e',
      );
    }
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
    try {
      // print('      🔹 TituloModel: _id');
      final id = json['_id'] as String;
      // print('      🔹 TituloModel: titulo_serie_hash');
      final tituloSerieHash = json['titulo_serie_hash'] as String;
      // print('      🔹 TituloModel: cod_serie');
      final codSerie = json['cod_serie'] as String;
      // print('      🔹 TituloModel: nome_serie');
      final nomeSerie = json['nome_serie'] as String;
      // print('      🔹 TituloModel: titulo');
      final titulo = json['titulo'] as String;
      // print('      🔹 TituloModel: usuario (nested)');
      final usuario = UsuarioModel.fromJson(
        json['usuario'] as Map<String, dynamic>,
      );

      return TituloModel(
        id: id,
        tituloSerieHash: tituloSerieHash,
        codSerie: codSerie,
        nomeSerie: nomeSerie,
        titulo: titulo,
        usuario: usuario,
      );
    } catch (e) {
      print('      ❌ ERRO no TituloModel.fromJson: $e');
      rethrow;
    }
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
    var currentField = '<inicializacao>';
    try {
      currentField = '_id';
      final id = json['_id'] as String;
      currentField = 'cpf_cnpj';
      final cpfCnpj = json['cpf_cnpj'] as String;
      currentField = 'nome';
      final nome = json['nome'] as String;
      currentField = 'email';
      final email = json['email'] as String;
      // Se for null, vamos usar string vazia temporariamente
      currentField = 'numero_telefone_acesso';
      final numeroTelefoneAcesso = json['numero_telefone_acesso'] as String?;

      if (numeroTelefoneAcesso == null) {
        throw Exception('numero_telefone_acesso não pode ser null');
      }

      return UsuarioModel(
        id: id,
        cpfCnpj: cpfCnpj,
        nome: nome,
        email: email,
        numeroTelefoneAcesso: numeroTelefoneAcesso,
      );
    } catch (e, stackTrace) {
      print('      ❌ ERRO no UsuarioModel.fromJson (campo: $currentField): $e');
      print(
        '      Stack: ${stackTrace.toString().split('\n').take(2).join('\n')}',
      );
      throw FormatException(
        'UsuarioModel.fromJson falhou no campo "$currentField": $e',
      );
    }
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
    var currentField = '<inicializacao>';
    try {
      currentField = '_id';
      final id = json['_id'] as String;
      currentField = 'cpf_cnpj';
      final cpfCnpj = json['cpf_cnpj'] as String;
      currentField = 'nome';
      final nome = json['nome'] as String;
      currentField = 'email';
      final email = json['email'] as String;

      return UsuarioSistemaModel(
        id: id,
        cpfCnpj: cpfCnpj,
        nome: nome,
        email: email,
      );
    } catch (e, stackTrace) {
      print(
        '          ❌ ERRO no UsuarioSistemaModel.fromJson (campo: $currentField): $e',
      );
      print(
        '          Stack: ${stackTrace.toString().split('\n').take(2).join('\n')}',
      );
      throw FormatException(
        'UsuarioSistemaModel.fromJson falhou no campo "$currentField": $e',
      );
    }
  }
}
