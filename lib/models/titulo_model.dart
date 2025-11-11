class TituloModel {
  final String id;
  final String tituloSerieHash;
  final String titulo;
  final String nomeSerie;
  final DateTime assinatura;
  final DateTime vencimento;
  final bool bloqueado;
  final String situacao;
  final UsuarioTitulo usuario;
  final bool requerAceiteUso;
  final bool mostraAceite;
  final String? termosDeUso;
  final int totalCortesias;
  final int totalCortesiasHoje;

  TituloModel({
    required this.id,
    required this.tituloSerieHash,
    required this.titulo,
    required this.nomeSerie,
    required this.assinatura,
    required this.vencimento,
    required this.bloqueado,
    required this.situacao,
    required this.usuario,
    required this.requerAceiteUso,
    required this.mostraAceite,
    this.termosDeUso,
    required this.totalCortesias,
    this.totalCortesiasHoje = 0,
  });

  factory TituloModel.fromJson(Map<String, dynamic> json) {
    return TituloModel(
      id: json['_id'] ?? '',
      tituloSerieHash: json['titulo_serie_hash'] ?? '',
      titulo: json['titulo'] ?? '',
      nomeSerie: json['nome_serie'] ?? '',
      assinatura: DateTime.parse(
        json['assinatura'] ?? DateTime.now().toIso8601String(),
      ),
      vencimento: DateTime.parse(
        json['vencimento'] ?? DateTime.now().toIso8601String(),
      ),
      bloqueado: json['bloqueado'] ?? false,
      situacao: json['situacao'] ?? '',
      usuario: UsuarioTitulo.fromJson(json['usuario'] ?? {}),
      requerAceiteUso: json['requer_aceite_uso'] ?? false,
      mostraAceite: json['mostra_aceite'] ?? false,
      termosDeUso: json['termos_de_uso'],
      totalCortesias: json['total_cortesias'] ?? 0,
      totalCortesiasHoje: json['total_cortesias_hoje'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo_serie_hash': tituloSerieHash,
      'nome_serie': nomeSerie,
      'assinatura': assinatura.toIso8601String(),
      'vencimento': vencimento.toIso8601String(),
      'bloqueado': bloqueado,
      'situacao': situacao,
      'usuario': usuario.toJson(),
      'requer_aceite_uso': requerAceiteUso,
      'mostra_aceite': mostraAceite,
      'termos_de_uso': termosDeUso,
      'total_cortesias': totalCortesias,
      'total_cortesias_hoje': totalCortesiasHoje,
    };
  }

  // Verifica se o título requer atenção
  bool get requerAtencao {
    // Título Pendente sempre requer atenção
    if (situacao.toUpperCase() == 'PENDENTE') {
      return true;
    }

    // Título Ativo e Bloqueado requer atenção
    if (situacao.toUpperCase() == 'ATIVO' && bloqueado) {
      return true;
    }

    return false;
  }

  // Status do título para exibição
  String get statusDisplay {
    if (situacao.toUpperCase() == 'PENDENTE') {
      return 'Pendente';
    }

    if (situacao.toUpperCase() == 'ATIVO') {
      if (bloqueado) {
        return 'Ativo (Bloqueado)';
      } else {
        return 'Ativo';
      }
    }

    return situacao;
  }

  // Cor do status baseado na situação
  String get statusColor {
    if (requerAtencao) {
      return 'warning'; // Laranja/Amarelo
    }
    return 'success'; // Verde
  }
}

class UsuarioTitulo {
  final String id;
  final String nome;
  final String cpfCnpj;
  final String email;
  final List<String> telefones;
  final String numeroTelefoneAcesso;

  UsuarioTitulo({
    required this.id,
    required this.nome,
    required this.cpfCnpj,
    required this.email,
    required this.telefones,
    required this.numeroTelefoneAcesso,
  });

  factory UsuarioTitulo.fromJson(Map<String, dynamic> json) {
    return UsuarioTitulo(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      cpfCnpj: json['cpf_cnpj'] ?? '',
      email: json['email'] ?? '',
      telefones: List<String>.from(json['telefones'] ?? []),
      numeroTelefoneAcesso: json['numero_telefone_acesso'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nome': nome,
      'cpf_cnpj': cpfCnpj,
      'email': email,
      'telefones': telefones,
      'numero_telefone_acesso': numeroTelefoneAcesso,
    };
  }
}
