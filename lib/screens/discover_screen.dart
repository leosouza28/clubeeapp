import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lottie/lottie.dart';
import '../services/app_config_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  // Key estável para o WebView; se você trocar a URL dinamicamente,
  // atualize também esta key para forçar um rebuild limpo quando necessário.
  final GlobalKey _webViewKey = GlobalKey(debugLabel: 'discover_webview');

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    final appConfigService = AppConfigService.instance;
    final url = appConfigService.appConfig?.urlSiteAtracoes;

    if (url == null || url.isEmpty) {
      setState(() {
        _errorMessage = 'URL de atrações não configurada';
        _isLoading = false;
      });
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            setState(() {
              _errorMessage = 'Erro ao carregar página: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      );

    _controller = controller;
    await _controller.loadRequest(Uri.parse(url));
  }

  Future<bool> _onWillPop() async {
    // Se puder voltar no histórico do webview, volta lá primeiro.
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    // Caso contrário, deixa o sistema lidar (voltar a aba anterior / sair)
    return true;
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    _initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final loader = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/lottie/summervibes.json',
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          const SizedBox(height: 16),
          Text('Descobrindo...', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );

    if (_errorMessage != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: SafeArea(
          child: Stack(
            children: [
              // Importante: evitar colocar WebView dentro de widgets "sliver" ou listas roláveis.
              // Aqui ela está diretamente no body.
              KeyedSubtree(
                // ajuda a não confundir elementos no tree reconciler
                key: _webViewKey,
                child: WebViewWidget(controller: _controller),
              ),
              // Overlay de loading com transição suave
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? Container(
                        key: const ValueKey('loading'),
                        color: Colors.white,
                        child: loader,
                      )
                    : const SizedBox.shrink(key: ValueKey('not_loading')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
