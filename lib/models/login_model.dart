import 'user_model.dart';

class LoginRequest {
  final String cpfCnpj;
  final String senha;

  LoginRequest({required this.cpfCnpj, required this.senha});

  Map<String, dynamic> toJson() {
    return {'cpf_cnpj': cpfCnpj, 'senha': senha};
  }
}

class LoginResponse {
  final UserModel user;
  final String token;
  final int iat;
  final int exp;

  LoginResponse({
    required this.user,
    required this.token,
    required this.iat,
    required this.exp,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // O token vem no formato "Bearer xxx", vamos extrair apenas o token
    String cleanToken = json['token'] ?? '';
    if (cleanToken.startsWith('Bearer ')) {
      cleanToken = cleanToken.substring(7);
    }

    return LoginResponse(
      user: UserModel.fromJson(json),
      token: cleanToken,
      iat: json['iat'] ?? 0,
      exp: json['exp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = user.toJson();
    result['token'] = 'Bearer $token';
    result['iat'] = iat;
    result['exp'] = exp;
    return result;
  }

  bool get isTokenValid {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return exp > now;
  }
}
