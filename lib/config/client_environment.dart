import 'package:flutter/foundation.dart';
import 'client_type.dart';

class ClientEnvironment {
  static ClientType get clientType {
    // Tentar obter o tipo de cliente das dart-define
    const clientTypeString = String.fromEnvironment(
      'CLIENT_TYPE',
      defaultValue: 'guara',
    );

    switch (clientTypeString.toLowerCase()) {
      case 'guara':
        return ClientType.guara;
      case 'vale_das_minas':
      case 'valedasminas':
        return ClientType.valeDasMinas;
      default:
        if (kDebugMode) {
          print(
            '⚠️ CLIENT_TYPE não reconhecido: $clientTypeString. Usando Guará como padrão.',
          );
        }
        return ClientType.guara;
    }
  }

  static bool get isProduction {
    return kReleaseMode;
  }

  static void printEnvironmentInfo() {
    if (kDebugMode) {
      print('🏢 Cliente: ${clientType.displayName}');
      print('🔧 Modo: ${isProduction ? 'Produção' : 'Desenvolvimento'}');
      print('📱 Platform: ${defaultTargetPlatform.name}');
    }
  }
}
