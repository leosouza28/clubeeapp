import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'config/client_type.dart';
import 'config/client_environment.dart';
import 'services/client_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Determinar o cliente baseado na variável de ambiente
  final clientType = ClientEnvironment.clientType;

  // Inicializar serviços
  await _initializeServices(clientType);

  runApp(const MyApp());
}

Future<void> _initializeServices(ClientType clientType) async {
  try {
    if (kDebugMode) {
      print('🚀 Inicializando serviços para: ${clientType.displayName}');
    }
    // Inicializar ClientService (que por sua vez inicializa o Firebase)
    await ClientService.instance.initialize(clientType);
    if (kDebugMode) {
      print('✅ Serviços inicializados com sucesso');
    }
  } catch (e) {
    if (kDebugMode) {
      // print('❌ Erro ao inicializar serviços: $e');
    }
    // Em caso de erro, continuar sem Firebase
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final clientService = ClientService.instance;
    final config = clientService.currentConfig;

    return MaterialApp(
      title: config.appName,
      theme: config.theme,
      home: const HomeScreen(),
      // Suas rotas aqui
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseFeatures();
  }

  Future<void> _initializeFirebaseFeatures() async {
    final firebaseService = ClientService.instance.firebaseService;

    // Obter token FCM
    _fcmToken = await firebaseService.getFCMToken();
    if (mounted) {
      setState(() {});
    }

    // Logar evento de abertura do app
    await firebaseService.logEvent('app_open', {
      'client_type': ClientService.instance.currentClientType.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientService = ClientService.instance;
    final config = clientService.currentConfig;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.appName),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuração Atual',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Cliente: ${config.clientType.displayName}'),
                    Text('API: ${config.apiBaseUrl}'),
                    Text('Package: ${config.androidPackageName}'),
                    Text('Bundle ID: ${config.iosBundleId}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'App: ${clientService.firebaseService.currentApp?.name ?? 'Não inicializado'}',
                    ),
                    Text(
                      'Cliente Firebase: ${clientService.firebaseService.currentClientType?.displayName ?? 'N/A'}',
                    ),
                    if (_fcmToken != null)
                      Text('FCM Token: ${_fcmToken!.substring(0, 20)}...'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testFirebaseAnalytics,
              child: const Text('Testar Analytics'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _switchClient,
              child: const Text('Trocar Cliente (Debug)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testFirebaseAnalytics() async {
    final firebaseService = ClientService.instance.firebaseService;

    await firebaseService.logEvent('button_pressed', {
      'button_name': 'test_analytics',
      'screen': 'home',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento enviado para Analytics!')),
      );
    }
  }

  Future<void> _switchClient() async {
    final currentClient = ClientService.instance.currentClientType;
    final newClient = currentClient == ClientType.guara
        ? ClientType.valeDasMinas
        : ClientType.guara;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Trocando Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Mudando para ${newClient.displayName}...'),
          ],
        ),
      ),
    );

    await ClientService.instance.setClient(newClient);

    if (!mounted) return;
    Navigator.of(context).pop();

    // Recarregar a tela para mostrar as novas configurações
    setState(() {
      _fcmToken = null;
    });

    _initializeFirebaseFeatures();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cliente alterado para ${newClient.displayName}!'),
      ),
    );
  }
}
