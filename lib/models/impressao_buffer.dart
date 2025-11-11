class ImpressaoBuffer {
  final List<ComandoImpressao> comandos;

  ImpressaoBuffer({required this.comandos});

  factory ImpressaoBuffer.fromJson(Map<String, dynamic> json) {
    return ImpressaoBuffer(
      comandos: (json['comandos'] as List<dynamic>)
          .map((e) => ComandoImpressao.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ComandoImpressao {
  final String tipo;
  final Map<String, dynamic> parametros;

  ComandoImpressao({required this.tipo, required this.parametros});

  factory ComandoImpressao.fromJson(Map<String, dynamic> json) {
    return ComandoImpressao(
      tipo: json['tipo'] as String,
      parametros: json['parametros'] as Map<String, dynamic>,
    );
  }
}
