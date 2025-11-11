class UserModel {
  final String id;
  final String nome;
  final String cpfCnpj;
  final String email;
  final bool criouContaSite;
  final UserProfile perfil;
  final String numeroTelefoneAcesso;
  final Club clube;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? genero;
  final String? dataNascimento;
  final DateTime? dataNascimentoDate;
  final UserAddress? enderecoPrimario;
  final String? estadoCivil;
  final String? rg;
  final List<String> telefones;
  final bool criouSenhaAcesso;
  final String? profileImage;
  final DateTime? profileImageAtualizacao;
  final String? profileImagePath;
  final String? profileImagePublic;
  final String status;
  final String associadoStatus;
  final String? emailSecundario;
  final String tipoDocumento;
  final UserProfileV2? perfilV2;
  final DateTime? ultimoAcessoViaCodigo;
  final List<dynamic> titulos;

  // Propriedades de endereço diretas (da API logged-user)
  final String? enderecoCep;
  final String? enderecoLogradouro;
  final String? enderecoNumero;
  final String? enderecoBairro;
  final String? enderecoCidade;
  final String? enderecoEstado;
  final String? enderecoComplemento;

  UserModel({
    required this.id,
    required this.nome,
    required this.cpfCnpj,
    required this.email,
    required this.criouContaSite,
    required this.perfil,
    required this.numeroTelefoneAcesso,
    required this.clube,
    required this.createdAt,
    required this.updatedAt,
    this.genero,
    this.dataNascimento,
    this.dataNascimentoDate,
    this.enderecoPrimario,
    this.estadoCivil,
    this.rg,
    required this.telefones,
    required this.criouSenhaAcesso,
    this.profileImage,
    this.profileImageAtualizacao,
    this.profileImagePath,
    this.profileImagePublic,
    required this.status,
    required this.associadoStatus,
    this.emailSecundario,
    required this.tipoDocumento,
    this.perfilV2,
    this.ultimoAcessoViaCodigo,
    required this.titulos,
    this.enderecoCep,
    this.enderecoLogradouro,
    this.enderecoNumero,
    this.enderecoBairro,
    this.enderecoCidade,
    this.enderecoEstado,
    this.enderecoComplemento,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      email: json['email'] ?? '',
      criouContaSite: json['criou_conta_site'] ?? false,
      perfil: UserProfile.fromJson(json['perfil'] ?? {}),
      numeroTelefoneAcesso: json['numero_telefone_acesso'] ?? '',
      clube: Club.fromJson(json['clube'] ?? {}),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      genero: json['genero'],
      dataNascimento: json['data_nascimento'],
      dataNascimentoDate: json['data_nascimento_date'] != null
          ? DateTime.parse(json['data_nascimento_date'])
          : null,
      enderecoPrimario: json['endereco_primario'] != null
          ? UserAddress.fromJson(json['endereco_primario'])
          : null,
      estadoCivil: json['estado_civil'],
      rg: json['rg'],
      telefones: List<String>.from(json['telefones'] ?? []),
      criouSenhaAcesso: json['criou_senha_acesso'] ?? false,
      profileImage: json['profile_image'],
      profileImageAtualizacao: json['profile_image_atualizacao'] != null
          ? DateTime.parse(json['profile_image_atualizacao'])
          : null,
      profileImagePath: json['profile_image_path'],
      profileImagePublic: json['profile_image_public'],
      status: json['status'] ?? '',
      associadoStatus: json['associado_status'] ?? '',
      emailSecundario: json['email_secundario'],
      tipoDocumento: json['tipo_documento'] ?? '',
      perfilV2: json['perfil_v2'] != null
          ? UserProfileV2.fromJson(json['perfil_v2'])
          : null,
      ultimoAcessoViaCodigo: json['ultimo_acesso_via_codigo'] != null
          ? DateTime.parse(json['ultimo_acesso_via_codigo'])
          : null,
      titulos: json['titulos'] ?? [],
      // Propriedades de endereço diretas (da API logged-user)
      enderecoCep: json['endereco_cep'],
      enderecoLogradouro: json['endereco_logradouro'],
      enderecoNumero: json['endereco_numero'],
      enderecoBairro: json['endereco_bairro'],
      enderecoCidade: json['endereco_cidade'],
      enderecoEstado: json['endereco_estado'],
      enderecoComplemento: json['endereco_complemento'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nome': nome,
      'cpf_cnpj': cpfCnpj,
      'email': email,
      'criou_conta_site': criouContaSite,
      'perfil': perfil.toJson(),
      'numero_telefone_acesso': numeroTelefoneAcesso,
      'clube': clube.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'genero': genero,
      'data_nascimento': dataNascimento,
      'data_nascimento_date': dataNascimentoDate?.toIso8601String(),
      'endereco_primario': enderecoPrimario?.toJson(),
      'estado_civil': estadoCivil,
      'rg': rg,
      'telefones': telefones,
      'criou_senha_acesso': criouSenhaAcesso,
      'profile_image': profileImage,
      'profile_image_atualizacao': profileImageAtualizacao?.toIso8601String(),
      'profile_image_path': profileImagePath,
      'profile_image_public': profileImagePublic,
      'status': status,
      'associado_status': associadoStatus,
      'email_secundario': emailSecundario,
      'tipo_documento': tipoDocumento,
      'perfil_v2': perfilV2?.toJson(),
      'ultimo_acesso_via_codigo': ultimoAcessoViaCodigo?.toIso8601String(),
      'titulos': titulos,
      // Propriedades de endereço diretas
      'endereco_cep': enderecoCep,
      'endereco_logradouro': enderecoLogradouro,
      'endereco_numero': enderecoNumero,
      'endereco_bairro': enderecoBairro,
      'endereco_cidade': enderecoCidade,
      'endereco_estado': enderecoEstado,
      'endereco_complemento': enderecoComplemento,
    };
  }

  // Método copyWith para criar uma cópia do usuário com algumas propriedades alteradas
  UserModel copyWith({
    String? id,
    String? nome,
    String? cpfCnpj,
    String? email,
    bool? criouContaSite,
    UserProfile? perfil,
    String? numeroTelefoneAcesso,
    Club? clube,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? genero,
    String? dataNascimento,
    DateTime? dataNascimentoDate,
    UserAddress? enderecoPrimario,
    String? estadoCivil,
    String? rg,
    List<String>? telefones,
    bool? criouSenhaAcesso,
    String? profileImage,
    DateTime? profileImageAtualizacao,
    String? profileImagePath,
    String? profileImagePublic,
    String? status,
    String? associadoStatus,
    String? emailSecundario,
    String? tipoDocumento,
    UserProfileV2? perfilV2,
    DateTime? ultimoAcessoViaCodigo,
    List<dynamic>? titulos,
    String? enderecoCep,
    String? enderecoLogradouro,
    String? enderecoNumero,
    String? enderecoBairro,
    String? enderecoCidade,
    String? enderecoEstado,
    String? enderecoComplemento,
  }) {
    return UserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cpfCnpj: cpfCnpj ?? this.cpfCnpj,
      email: email ?? this.email,
      criouContaSite: criouContaSite ?? this.criouContaSite,
      perfil: perfil ?? this.perfil,
      numeroTelefoneAcesso: numeroTelefoneAcesso ?? this.numeroTelefoneAcesso,
      clube: clube ?? this.clube,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      genero: genero ?? this.genero,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      dataNascimentoDate: dataNascimentoDate ?? this.dataNascimentoDate,
      enderecoPrimario: enderecoPrimario ?? this.enderecoPrimario,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      rg: rg ?? this.rg,
      telefones: telefones ?? this.telefones,
      criouSenhaAcesso: criouSenhaAcesso ?? this.criouSenhaAcesso,
      profileImage: profileImage ?? this.profileImage,
      profileImageAtualizacao:
          profileImageAtualizacao ?? this.profileImageAtualizacao,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      profileImagePublic: profileImagePublic ?? this.profileImagePublic,
      status: status ?? this.status,
      associadoStatus: associadoStatus ?? this.associadoStatus,
      emailSecundario: emailSecundario ?? this.emailSecundario,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      perfilV2: perfilV2 ?? this.perfilV2,
      ultimoAcessoViaCodigo:
          ultimoAcessoViaCodigo ?? this.ultimoAcessoViaCodigo,
      titulos: titulos ?? this.titulos,
      enderecoCep: enderecoCep ?? this.enderecoCep,
      enderecoLogradouro: enderecoLogradouro ?? this.enderecoLogradouro,
      enderecoNumero: enderecoNumero ?? this.enderecoNumero,
      enderecoBairro: enderecoBairro ?? this.enderecoBairro,
      enderecoCidade: enderecoCidade ?? this.enderecoCidade,
      enderecoEstado: enderecoEstado ?? this.enderecoEstado,
      enderecoComplemento: enderecoComplemento ?? this.enderecoComplemento,
    );
  }
}

class UserProfile {
  final String id;
  final String nome;
  final List<int> permissoes;

  UserProfile({required this.id, required this.nome, required this.permissoes});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      permissoes: List<int>.from(json['permissoes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'nome': nome, 'permissoes': permissoes};
  }
}

class UserProfileV2 {
  final String id;
  final String nome;
  final List<String> scopes;

  UserProfileV2({required this.id, required this.nome, required this.scopes});

  factory UserProfileV2.fromJson(Map<String, dynamic> json) {
    return UserProfileV2(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      scopes: List<String>.from(json['scopes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'nome': nome, 'scopes': scopes};
  }
}

class Club {
  final String id;
  final String nome;

  Club({required this.id, required this.nome});

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(id: json['_id'] ?? '', nome: json['nome'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'nome': nome};
  }
}

class UserAddress {
  final String cep;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;

  UserAddress({
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      cep: json['cep'] ?? '',
      logradouro: json['logradouro'] ?? '',
      numero: json['numero'] ?? '',
      complemento: json['complemento'],
      bairro: json['bairro'] ?? '',
      cidade: json['cidade'] ?? '',
      estado: json['estado'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
    };
  }
}
