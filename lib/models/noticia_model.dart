class NoticiaModel {
  final String id;
  final String titulo;
  final String corpo;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ImagemModel> imagens;
  final CriadoPorModel criadoPor;
  final CriadoPorModel ultimaAlteracao;

  NoticiaModel({
    required this.id,
    required this.titulo,
    required this.corpo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.imagens,
    required this.criadoPor,
    required this.ultimaAlteracao,
  });

  factory NoticiaModel.fromJson(Map<String, dynamic> json) {
    return NoticiaModel(
      id: json['_id'] ?? '',
      titulo: json['titulo'] ?? '',
      corpo: json['corpo'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      imagens:
          (json['imagens'] as List<dynamic>?)
              ?.map((e) => ImagemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      criadoPor: CriadoPorModel.fromJson(json['criado_por'] ?? {}),
      ultimaAlteracao: CriadoPorModel.fromJson(json['ultima_alteracao'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo': titulo,
      'corpo': corpo,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'imagens': imagens.map((e) => e.toJson()).toList(),
      'criado_por': criadoPor.toJson(),
      'ultima_alteracao': ultimaAlteracao.toJson(),
    };
  }
}

class ImagemModel {
  final String url;
  final String id;

  ImagemModel({required this.url, required this.id});

  factory ImagemModel.fromJson(Map<String, dynamic> json) {
    return ImagemModel(url: json['url'] ?? '', id: json['_id'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'url': url, '_id': id};
  }
}

class CriadoPorModel {
  final UsuarioModel usuario;
  final DateTime dataHora;

  CriadoPorModel({required this.usuario, required this.dataHora});

  factory CriadoPorModel.fromJson(Map<String, dynamic> json) {
    return CriadoPorModel(
      usuario: UsuarioModel.fromJson(json['usuario'] ?? {}),
      dataHora: DateTime.parse(
        json['data_hora'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario': usuario.toJson(),
      'data_hora': dataHora.toIso8601String(),
    };
  }
}

class UsuarioModel {
  final String id;
  final String cpfCnpj;
  final String nome;

  UsuarioModel({required this.id, required this.cpfCnpj, required this.nome});

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['_id'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      nome: json['nome'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'cpf_cnpj': cpfCnpj, 'nome': nome};
  }
}

class NoticiasResponseModel {
  final List<NoticiaModel> lista;
  final int total;

  NoticiasResponseModel({required this.lista, required this.total});

  factory NoticiasResponseModel.fromJson(Map<String, dynamic> json) {
    return NoticiasResponseModel(
      lista:
          (json['lista'] as List<dynamic>?)
              ?.map((e) => NoticiaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'lista': lista.map((e) => e.toJson()).toList(), 'total': total};
  }
}
