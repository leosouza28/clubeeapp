class TagModel {
  final String id;
  final String descricao;
  final String tipo;

  const TagModel({
    required this.id,
    required this.descricao,
    required this.tipo,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
    );
  }
}
