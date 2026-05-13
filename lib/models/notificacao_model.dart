class NotificacaoModel {
  final String id;
  final String messageType;
  final String titulo;
  final String corpo;
  final DateTime createdAt;
  final bool isByUser;
  final Map<String, dynamic>? data;

  NotificacaoModel({
    required this.id,
    required this.messageType,
    required this.titulo,
    required this.corpo,
    required this.createdAt,
    required this.isByUser,
    this.data,
  });

  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    return NotificacaoModel(
      id: json['_id'] ?? '',
      messageType: json['message_type'] ?? '',
      titulo: json['titulo'] ?? '',
      corpo: json['corpo'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isByUser: json['is_by_user'] ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'message_type': messageType,
      'titulo': titulo,
      'corpo': corpo,
      'created_at': createdAt.toIso8601String(),
      'is_by_user': isByUser,
      'data': data,
    };
  }
}
