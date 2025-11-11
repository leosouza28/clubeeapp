import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'client_type.dart';
import '../firebase_options_guara.dart' as firebase_guara;
import '../firebase_options_valedasminas.dart' as firebase_valedasminas;

class ClientConfig {
  final ClientType clientType;
  final String appName;
  final String logoPath;
  final ThemeData theme;
  final String primaryColor;
  final String secondaryColor;
  final String apiBaseUrl;
  final String linkPrivacidade;
  final String iosBundleId;
  final String androidPackageName;
  final FirebaseOptions firebaseOptions;
  final Map<String, dynamic> customSettings;
  final String deepLinkScheme;
  final String deepLinkHost;
  final List<String> alternativeHosts;
  final String? iconPath;

  const ClientConfig({
    required this.clientType,
    required this.appName,
    required this.logoPath,
    required this.theme,
    required this.primaryColor,
    required this.secondaryColor,
    required this.apiBaseUrl,
    required this.linkPrivacidade,
    required this.iosBundleId,
    required this.androidPackageName,
    required this.firebaseOptions,
    required this.deepLinkScheme,
    required this.deepLinkHost,
    this.iconPath,
    this.customSettings = const {},
    this.alternativeHosts = const [],
  });

  factory ClientConfig.fromClientType(ClientType clientType) {
    switch (clientType) {
      case ClientType.guara:
        return ClientConfig(
          clientType: clientType,
          appName: 'Guará Acqua Park',
          logoPath: 'assets/images/guara/logo.png',
          theme: _createGuaraTheme(),
          primaryColor: '#1976D2',
          secondaryColor: '#FF9800',
          apiBaseUrl: 'https://api.guarapark.app',
          linkPrivacidade: 'https://guarapark.app/politicas',
          iosBundleId: 'com.lsdevelopers.guaraapp',
          androidPackageName: 'com.guaraapp',
          firebaseOptions:
              firebase_guara.DefaultFirebaseOptions.currentPlatform,
          deepLinkScheme: 'guaraapp',
          deepLinkHost: 'app.guarapark.com',
          alternativeHosts: ['guarapark.app', 'www.guarapark.app'],
          customSettings: {
            // 'maxUsers': 1000,
          },
          iconPath: 'assets/images/guara/home.png',
        );

      case ClientType.valeDasMinas:
        return ClientConfig(
          clientType: clientType,
          appName: 'Vale das Minas Park',
          logoPath: 'assets/images/vale_das_minas/logo.png',
          theme: _createValeDasMinasTheme(),
          primaryColor: '#4CAF50',
          secondaryColor: '#FFC107',
          apiBaseUrl: 'https://api-valedasminaspark.lsdevelopers.dev',
          linkPrivacidade:
              'https://api-valedasminaspark.lsdevelopers.dev/politicas',
          iosBundleId: 'com.lsdevelopers.valedasminas',
          androidPackageName: 'com.valedasminas',
          firebaseOptions:
              firebase_valedasminas.DefaultFirebaseOptions.currentPlatform,
          deepLinkScheme: 'valedasminasapp',
          deepLinkHost: 'app.valedasminas.com',
          alternativeHosts: ['valedasminas.app', 'www.valedasminas.app'],
          customSettings: {
            // 'maxUsers': 500,
          },
          iconPath: 'assets/images/vale_das_minas/home.png',
        );
    }
  }

  static ThemeData _createGuaraTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData _createValeDasMinasTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
