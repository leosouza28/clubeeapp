class AppConfigModel {
  final String id;
  final ClubeModel clube;
  final BilheteriaAppConfigModel bilheteriaAppConfig;
  final List<ContatoModel> contatos;
  final String urlSiteAtracoes;
  final String urlSitePoliticaPrivacidade;
  final String urlAdministrativoV1;
  final String urlAdministrativoV2;
  final String urlCompliance;
  final String urlSiteCortesias;

  AppConfigModel({
    required this.id,
    required this.clube,
    required this.bilheteriaAppConfig,
    required this.contatos,
    required this.urlSiteAtracoes,
    required this.urlSitePoliticaPrivacidade,
    required this.urlAdministrativoV1,
    required this.urlAdministrativoV2,
    required this.urlCompliance,
    required this.urlSiteCortesias,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      id: json['_id'] ?? '',
      clube: ClubeModel.fromJson(json['clube'] ?? {}),
      bilheteriaAppConfig: BilheteriaAppConfigModel.fromJson(
        json['bilheteria_app_config'] ?? {},
      ),
      contatos:
          (json['contatos'] as List<dynamic>?)
              ?.map((e) => ContatoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      urlSiteAtracoes: json['url_site_atracoes'] ?? '',
      urlSitePoliticaPrivacidade: json['url_site_politica_privacidade'] ?? '',
      urlAdministrativoV1: json['url_administrativo_v1'] ?? '',
      urlAdministrativoV2: json['url_administrativo_v2'] ?? '',
      urlCompliance: json['url_compliance'] ?? '',
      urlSiteCortesias: json['url_site_cortesias'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'clube': clube.toJson(),
      'bilheteria_app_config': bilheteriaAppConfig.toJson(),
      'contatos': contatos.map((e) => e.toJson()).toList(),
      'url_site_atracoes': urlSiteAtracoes,
      'url_site_politica_privacidade': urlSitePoliticaPrivacidade,
      'url_administrativo_v1': urlAdministrativoV1,
      'url_administrativo_v2': urlAdministrativoV2,
      'url_compliance': urlCompliance,
      'url_site_cortesias': urlSiteCortesias,
    };
  }
}

class ClubeModel {
  final String id;
  final String nome;

  ClubeModel({required this.id, required this.nome});

  factory ClubeModel.fromJson(Map<String, dynamic> json) {
    return ClubeModel(id: json['_id'] ?? '', nome: json['nome'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'nome': nome};
  }
}

class BilheteriaAppConfigModel {
  final bool ativada;
  final String tipo;
  final String urlSiteExterno;

  BilheteriaAppConfigModel({
    required this.ativada,
    required this.tipo,
    required this.urlSiteExterno,
  });

  factory BilheteriaAppConfigModel.fromJson(Map<String, dynamic> json) {
    return BilheteriaAppConfigModel(
      ativada: json['ativada'] ?? false,
      tipo: json['tipo'] ?? '',
      urlSiteExterno: json['url_site_externo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ativada': ativada,
      'tipo': tipo,
      'url_site_externo': urlSiteExterno,
    };
  }

  bool get isSiteExterno => tipo == 'SITE_EXTERNO';
}

class ContatoModel {
  final String id;
  final String tipo;
  final String valor;
  final String descricao;

  ContatoModel({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.descricao,
  });

  factory ContatoModel.fromJson(Map<String, dynamic> json) {
    return ContatoModel(
      id: json['_id'] ?? '',
      tipo: json['tipo'] ?? '',
      valor: json['valor'] ?? '',
      descricao: json['descricao'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'tipo': tipo, 'valor': valor, 'descricao': descricao};
  }

  bool get isWhatsApp => tipo == 'WHATSAPP';
  bool get isTelefone => tipo == 'TELEFONE';
  bool get isEmail => tipo == 'E-MAIL';
}
