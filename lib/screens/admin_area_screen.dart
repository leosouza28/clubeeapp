import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_clubee/services/api_service.dart';
import 'package:app_clubee/services/auth_service.dart';
import 'package:app_clubee/services/client_service.dart';
import 'package:app_clubee/services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

import '../services/app_config_service.dart';

class AdminAreaScreen extends StatefulWidget {
  const AdminAreaScreen({super.key});

  @override
  State<AdminAreaScreen> createState() => _AdminAreaScreenState();
}

class _AdminAreaScreenState extends State<AdminAreaScreen> {
  late WebViewController _controller;
  BluetoothInfo? _savedPrinter;
  bool _isBluetoothPermissionGranted = false;
  bool _isConnecting = false;
  bool _isLoading = true;
  String? _errorMessage;

  final _log = LoggingService.instance;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _requestBluetoothPermission();
    await _loadSavedPrinter();
    _initializeWebView();
  }

  Future<void> _requestBluetoothPermission() async {
    try {
      if (Platform.isIOS) {
        // final bluetooth = await Permission.bluetooth.request();
        // _log.info('Permissão Bluetooth iOS: ${bluetooth.isGranted}');
        // if (bluetooth.isGranted) {
        //   setState(() {
        //     _isBluetoothPermissionGranted = bluetooth.isGranted;
        //   });
        // }
        setState(() {
          _isBluetoothPermissionGranted = true;
        });
      } else {
        // Request multiple permissions
        final bluetoothScan = await Permission.bluetoothScan.request();
        final bluetoothConnect = await Permission.bluetoothConnect.request();
        _log.info(
          'Permissões Bluetooth: '
          'Scan=${bluetoothScan.isGranted}, '
          'Connect=${bluetoothConnect.isGranted}, ',
        );
        setState(() {
          _isBluetoothPermissionGranted =
              bluetoothScan.isGranted && bluetoothConnect.isGranted;
        });
      }

      if (!_isBluetoothPermissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permissões Bluetooth são necessárias para impressão',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // debugPrint('Erro ao solicitar permissões: $e');
    }
  }

  Future<void> _loadSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPrinterJson = prefs.getString('saved_printer');

      if (savedPrinterJson != null) {
        final printerData = json.decode(savedPrinterJson);
        setState(() {
          _savedPrinter = BluetoothInfo(
            name: printerData['name'],
            macAdress: printerData['macAdress'],
          );
        });
      }
    } catch (e) {
      // debugPrint('Erro ao carregar impressora salva: $e');
    }
  }

  Future<void> _savePrinter(BluetoothInfo printer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final printerData = {
        'name': printer.name,
        'macAdress': printer.macAdress,
      };

      await prefs.setString('saved_printer', json.encode(printerData));

      setState(() {
        _savedPrinter = printer;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impressora ${printer.name} salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // debugPrint('Erro ao salvar impressora: $e');
    }
  }

  Future<void> _deleteSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_printer');

      setState(() {
        _savedPrinter = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impressora removida com sucesso!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      // debugPrint('Erro ao deletar impressora: $e');
    }
  }

  Future<void> _searchAndSelectPrinter() async {
    if (!_isBluetoothPermissionGranted) {
      await _requestBluetoothPermission();
      return;
    }

    try {
      setState(() {
        _isConnecting = true;
      });

      // Buscar dispositivos Bluetooth
      final List<BluetoothInfo> devices =
          await PrintBluetoothThermal.pairedBluetooths;

      setState(() {
        _isConnecting = false;
      });

      if (devices.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nenhuma impressora Bluetooth encontrada. Emparelhe uma impressora nas configurações do dispositivo.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Mostrar lista de impressoras
      if (mounted) {
        final selectedPrinter = await showDialog<BluetoothInfo>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Selecionar Impressora'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    title: Text(device.name),
                    subtitle: Text(device.macAdress),
                    onTap: () => Navigator.of(context).pop(device),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );

        if (selectedPrinter != null) {
          await _savePrinter(selectedPrinter);
        }
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar impressoras: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testPrint() async {
    if (_savedPrinter == null) return;
    try {
      setState(() {
        _isConnecting = true;
      });
      _log.debug(
        'savedPrinter: ${_savedPrinter!.name}, ${_savedPrinter!.macAdress}',
      );
      _log.debug('Iniciando teste de impressão...');
      // Conectar à impressora
      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: _savedPrinter!.macAdress,
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      _log.debug('Conexão com impressora: $connected');
      if (!connected) {
        throw Exception('Não foi possível conectar à impressora');
      }
      // Gerar comandos ESC/POS
      final profile = await CapabilityProfile.load();

      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text(
        'Hello World',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Teste de impressão',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Imprimir
      await PrintBluetoothThermal.writeBytes(bytes);

      setState(() {
        _isConnecting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teste de impressão enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na impressão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Desconectar da impressora
      try {
        _log.debug('Desconectando da impressora...');
        await Future.delayed(const Duration(seconds: 1000));
        await PrintBluetoothThermal.disconnect;
        _log.debug('Desconectado...');
      } catch (e) {
        debugPrint('Erro ao desconectar: $e');
      }
    }
  }

  Future<void> _handleWebMessage(String message) async {
    // Parse a mensagem no formato operacao:value
    _log.warning('messageReceived: $message');
    final parts = message.split(':');
    if (parts.length != 2) {
      _log.warning('Invalid message format: $message');
      return;
    }

    final operacao = parts[0];
    final value = parts[1];

    switch (operacao) {
      case 'print-agendamento':
        await _printAgendamento(value);
        break;
      default:
        _log.warning('Unknown operation: $operacao');
    }
  }

  Future<void> _printAgendamento(String idAgendamento) async {
    try {
      _log.debug('Fetching print buffer for agendamento: $idAgendamento');

      // Verificar se há impressora conectada
      if (_savedPrinter == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nenhuma impressora conectada! Por favor, conecte uma impressora primeiro.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _PrintingLoadingDialog(),
        );
      }

      // Obter buffer de impressão da API
      final clientService = ClientService.instance;
      final apiService = await ApiService.getInstance();
      final response = await apiService.getAgendamentoPrintBuffer(
        clientService.currentConfig.clientType,
        idAgendamento,
      );

      if (response['success'] == true && response['data'] != null) {
        final printBuffer = response['data'] as List<dynamic>;
        _log.debug('Print buffer received: ${printBuffer.length} items');

        // Conectar e imprimir
        await _printBuffer(printBuffer);

        // Aguardar 5 segundos para dar tempo da impressora processar
        await Future.delayed(const Duration(seconds: 5));

        // Fechar loading
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Fechar loading em caso de erro
        if (mounted) {
          Navigator.of(context).pop();
        }
        throw Exception('Erro ao buscar buffer de impressão');
      }
    } catch (e) {
      _log.error('Error printing agendamento', e);

      // Fechar loading se estiver aberto
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao imprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printBuffer(List<dynamic> printBuffer) async {
    if (_savedPrinter == null) return;

    try {
      _log.json(printBuffer);

      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: _savedPrinter!.macAdress,
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!connected) {
        throw Exception('Não foi possível conectar à impressora');
      }
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      final linesAfter = Platform.isIOS ? 0 : -1;
      // Processar cada item do buffer
      final bytesClear = generator.reset();
      await PrintBluetoothThermal.writeBytes(bytesClear);

      for (final item in printBuffer) {
        final tipo = item['tipo'] ?? '';

        if (tipo == 'image') {
          // Imprimir imagem base64
          final imageData = item['data'] as String;
          final imageBytes = base64Decode(imageData);
          final image = img.decodeImage(imageBytes);

          if (image != null) {
            if (Platform.isAndroid) {
              final printBytes = generator.image(image);
              await PrintBluetoothThermal.writeBytes(printBytes);
              await Future.delayed(const Duration(milliseconds: 1000));
            } else {
              final printBytes = generator.imageRaster(image);
              await PrintBluetoothThermal.writeBytes(printBytes);
              await Future.delayed(const Duration(milliseconds: 2500));
            }
          }
        } else if (tipo == 'linha') {
          // Quebrar linhas
          final printBytesBlankChar = generator.text(
            ' ',
            styles: PosStyles(align: PosAlign.left),
            linesAfter: linesAfter,
          );
          await PrintBluetoothThermal.writeBytes(printBytesBlankChar);
          await Future.delayed(const Duration(milliseconds: 50));
        } else if (tipo == '' || tipo == 'text') {
          // Imprimir texto
          final texto = item['texto'] ?? '';
          final printBytes = generator.text(
            texto,
            styles: PosStyles(
              align: PosAlign.left,
              bold: item['negrito'] ? true : false,
            ),
            linesAfter: linesAfter,
          );
          await PrintBluetoothThermal.writeBytes(printBytes);
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
      // Imprimir
    } catch (e) {
      _log.error('Error printing buffer', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao imprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      await PrintBluetoothThermal.disconnect;
    }
  }

  Future<void> _initializeWebView() async {
    // Obtém a URL da área administrativa do AppConfig
    final appConfigService = AppConfigService.instance;
    if (!appConfigService.isLoaded ||
        appConfigService.appConfig == null ||
        appConfigService.appConfig!.urlAdministrativoV2.isEmpty) {
      _log.error('AppConfigService não inicializado');
      return;
    }
    final authService = await AuthService.getInstance();
    final currentToken = await authService.getCurrentToken();

    final String tokenValueWithoutBearer = currentToken!.replaceFirst(
      'Bearer ',
      '',
    );

    final adminUrl = appConfigService.appConfig?.urlAdministrativoV2;

    final adminUrlWithToken =
        '$adminUrl/refresh-token?token=$tokenValueWithoutBearer';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'AppChannel',
        onMessageReceived: (message) async {
          try {
            final data = message.message;
            _log.debug('AppChannel message: $data');
            _handleWebMessage(data);
            // Aqui você pode processar diferentes tipos de mensagens do JavaScript
            // Por exemplo: navegação, notificações, etc.
          } catch (e) {
            // debugPrint('Erro ao processar mensagem JavaScript: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            // Injetar JavaScript para definir window.isApp = true
            _controller.runJavaScript('''
                window.isApp = true;
                window.sendToFlutter = (payload)=>{
                  AppChannel.postMessage(payload);
                };
              ''');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Garantir que o JavaScript seja injetado também após o carregamento
            _controller.runJavaScript('''
                window.isApp = true;
                window.sendToFlutter = (payload)=>{
                  AppChannel.postMessage(payload);
                };
              ''');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = 'Erro ao carregar página: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(adminUrlWithToken));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área Administrativa'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'search_printer':
                  _searchAndSelectPrinter();
                  break;
                case 'test_print':
                  _testPrint();
                  break;
                case 'delete_printer':
                  _deleteSavedPrinter();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'search_printer',
                enabled: !_isConnecting,
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: _isConnecting ? Colors.grey : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Buscar Impressora',
                      style: TextStyle(
                        color: _isConnecting ? Colors.grey : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'test_print',
                enabled: _savedPrinter != null && !_isConnecting,
                child: Row(
                  children: [
                    Icon(
                      Icons.print,
                      color: (_savedPrinter == null || _isConnecting)
                          ? Colors.grey
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Testar Impressão',
                      style: TextStyle(
                        color: (_savedPrinter == null || _isConnecting)
                            ? Colors.grey
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete_printer',
                enabled: _savedPrinter != null && !_isConnecting,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: (_savedPrinter == null || _isConnecting)
                          ? Colors.grey
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Excluir Impressora',
                      style: TextStyle(
                        color: (_savedPrinter == null || _isConnecting)
                            ? Colors.grey
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Status da impressora
          if (_savedPrinter != null)
            Container(
              width: double.infinity,
              color: Colors.green.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.print, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Impressora: ${_savedPrinter!.name}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isConnecting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                ],
              ),
            ),

          // WebView
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}

class _PrintingLoadingDialog extends StatelessWidget {
  const _PrintingLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone animado de impressora
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Icon(
                      Icons.print,
                      size: 80,
                      color: Theme.of(context).primaryColor.withOpacity(value),
                    ),
                  );
                },
                onEnd: () {
                  // Reiniciar animação
                },
              ),
              const SizedBox(height: 24),

              // Indicador de progresso
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Texto
              Text(
                'Imprimindo...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aguarde enquanto processamos\na impressão',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
