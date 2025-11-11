class CortesiaDisponivelModel {
  final String tipo;
  final int quantidade;

  CortesiaDisponivelModel({required this.tipo, required this.quantidade});

  factory CortesiaDisponivelModel.fromJson(Map<String, dynamic> json) {
    return CortesiaDisponivelModel(
      tipo: json['tipo'] ?? '',
      quantidade: json['qtd'] ?? 0,
    );
  }

  String get tipoDisplay {
    switch (tipo) {
      case 'CONTRATO':
        return 'Day-Use Contratual';
      case 'PROMOCIONAL':
        return 'Cortesia Promocional';
      default:
        return tipo;
    }
  }
}

class ReservaRequest {
  final bool concordo;
  final int quantidade;
  final String retirar;
  final String data;
  final bool isFormattedData;
  final String tituloId;
  final String tipoCortesia;
  final int versaoCortesia;

  ReservaRequest({
    required this.concordo,
    required this.quantidade,
    required this.retirar,
    required this.data,
    required this.isFormattedData,
    required this.tituloId,
    required this.tipoCortesia,
    required this.versaoCortesia,
  });

  Map<String, dynamic> toJson() {
    return {
      'concordo': concordo,
      'qtd': quantidade,
      'retirar': retirar,
      'data': data,
      'is_formatted_data': isFormattedData,
      'titulo_id': tituloId,
      'tipo_cortesia': tipoCortesia,
      'versao_cortesia': versaoCortesia,
    };
  }
}

class ReservaResponse {
  final String id;
  final String hash;

  ReservaResponse({required this.id, required this.hash});

  factory ReservaResponse.fromJson(Map<String, dynamic> json) {
    return ReservaResponse(id: json['_id'] ?? '', hash: json['hash'] ?? '');
  }
}
