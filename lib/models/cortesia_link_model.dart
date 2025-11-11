class CortesiaLinkModel {
  final String id;
  final String hash;
  final ClubeInfo clube;
  final String status;
  final String tipoCortesia;
  final String tipoUsuarioRetirada;
  final TituloInfo titulo;
  final int totalCortesias;
  final int totalCortesiasRetiradas;
  final UsuarioInfo usuario;
  final int versaoCortesia;
  final DateTime data;
  final DateTime createdAt;

  CortesiaLinkModel({
    required this.id,
    required this.hash,
    required this.clube,
    required this.status,
    required this.tipoCortesia,
    required this.tipoUsuarioRetirada,
    required this.titulo,
    required this.totalCortesias,
    required this.totalCortesiasRetiradas,
    required this.usuario,
    required this.versaoCortesia,
    required this.data,
    required this.createdAt,
  });

  factory CortesiaLinkModel.fromJson(Map<String, dynamic> json) {
    return CortesiaLinkModel(
      id: json['_id'] ?? '',
      hash: json['hash'] ?? '',
      clube: ClubeInfo.fromJson(json['clube'] ?? {}),
      status: json['status'] ?? '',
      tipoCortesia: json['tipo_cortesia'] ?? '',
      tipoUsuarioRetirada: json['tipo_usuario_retirada'] ?? '',
      titulo: TituloInfo.fromJson(json['titulo'] ?? {}),
      totalCortesias: json['total_cortesias'] ?? 0,
      totalCortesiasRetiradas: json['total_cortesias_retiradas'] ?? 0,
      usuario: UsuarioInfo.fromJson(json['usuario'] ?? {}),
      versaoCortesia: json['versao_cortesia'] ?? 0,
      data: DateTime.parse(json['data'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  bool get podeSerPreenchida {
    return status == 'AGUARDANDO VINCULO' && versaoCortesia == 2;
  }

  int get cortesiasDisponiveis {
    return totalCortesias - totalCortesiasRetiradas;
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

class TituloInfo {
  final String id;
  final String tituloSerieHash;
  final String codSerie;
  final String nomeSerie;
  final String titulo;
  final UsuarioTituloInfo usuario;

  TituloInfo({
    required this.id,
    required this.tituloSerieHash,
    required this.codSerie,
    required this.nomeSerie,
    required this.titulo,
    required this.usuario,
  });

  factory TituloInfo.fromJson(Map<String, dynamic> json) {
    return TituloInfo(
      id: json['_id'] ?? '',
      tituloSerieHash: json['titulo_serie_hash'] ?? '',
      codSerie: json['cod_serie'] ?? '',
      nomeSerie: json['nome_serie'] ?? '',
      titulo: json['titulo'] ?? '',
      usuario: UsuarioTituloInfo.fromJson(json['usuario'] ?? {}),
    );
  }
}

class UsuarioTituloInfo {
  final String id;
  final String cpfCnpj;
  final String nome;
  final String email;
  final String numeroTelefoneAcesso;

  UsuarioTituloInfo({
    required this.id,
    required this.cpfCnpj,
    required this.nome,
    required this.email,
    required this.numeroTelefoneAcesso,
  });

  factory UsuarioTituloInfo.fromJson(Map<String, dynamic> json) {
    return UsuarioTituloInfo(
      id: json['_id'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      numeroTelefoneAcesso: json['numero_telefone_acesso'] ?? '',
    );
  }
}

class UsuarioInfo {
  final String id;
  final String cpfCnpj;
  final String nome;
  final String email;
  final String numeroTelefoneAcesso;

  UsuarioInfo({
    required this.id,
    required this.cpfCnpj,
    required this.nome,
    required this.email,
    required this.numeroTelefoneAcesso,
  });

  factory UsuarioInfo.fromJson(Map<String, dynamic> json) {
    return UsuarioInfo(
      id: json['_id'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      numeroTelefoneAcesso: json['numero_telefone_acesso'] ?? '',
    );
  }
}

class UsuarioGeralModel {
  final String id;
  final String nome;
  final String cpf;
  final String telefone;
  final String email;
  final String dataNascimento;
  final bool possuiSenhaCadastrada;

  UsuarioGeralModel({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.email,
    required this.dataNascimento,
    required this.possuiSenhaCadastrada,
  });

  factory UsuarioGeralModel.fromJson(Map<String, dynamic> json) {
    return UsuarioGeralModel(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      cpf: json['cpf'] ?? '',
      telefone: json['telefone'] ?? '',
      email: json['email'] ?? '',
      dataNascimento: json['data_nascimento'] ?? '',
      possuiSenhaCadastrada: json['possui_senha_cadastrada'] ?? false,
    );
  }
}
