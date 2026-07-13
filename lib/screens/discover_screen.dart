import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lottie/lottie.dart';
import '../services/app_config_service.dart';

class DiscoverScreen extends StatefulWidget {
  /// Quando false, o WebView é destruído para liberar o Chromium da main thread.
  final bool isActive;

  const DiscoverScreen({super.key, this.isActive = false});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isInitializing = false;
  String? _errorMessage;

  final GlobalKey _webViewKey = GlobalKey(debugLabel: 'discover_webview');

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _ensureWebView();
    }
  }

  @override
  void didUpdateWidget(DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;

    if (widget.isActive) {
      _ensureWebView();
    } else {
      // Parent já vai rebuildar — não chama setState aqui.
      _tearDownWebView();
    }
  }

  @override
  void dispose() {
    _tearDownWebView();
    super.dispose();
  }

  void _tearDownWebView({bool notify = false}) {
    // Remover o controller faz o WebViewWidget sair da árvore e libera o
    // processo Chromium — principal mitigação do ANR nativePollOnce.
    _controller = null;
    _isInitializing = false;
    _isLoading = true;
    _errorMessage = null;
    if (notify && mounted) setState(() {});
  }

  Future<void> _ensureWebView() async {
    if (_controller != null || _isInitializing) return;
    await _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    if (_isInitializing) return;
    _isInitializing = true;

    final appConfigService = AppConfigService.instance;
    final url = appConfigService.appConfig?.urlSiteAtracoes;

    if (url == null || url.isEmpty) {
      _isInitializing = false;
      if (!mounted) return;
      setState(() {
        _errorMessage = 'URL de atrações não configurada';
        _isLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _errorMessage = null;
        _isLoading = true;
      });
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted || !widget.isActive) return;
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (!mounted || !widget.isActive) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted || !widget.isActive) return;
            setState(() {
              _errorMessage = 'Erro ao carregar página: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      );

    // Se o usuário saiu da aba durante o setup, descarta o controller.
    if (!mounted || !widget.isActive) {
      _isInitializing = false;
      return;
    }

    _controller = controller;
    _isInitializing = false;

    if (mounted) setState(() {});

    try {
      await controller.loadRequest(Uri.parse(url));
    } catch (_) {
      if (!mounted || !widget.isActive) return;
      setState(() {
        _errorMessage = 'Erro ao carregar página';
        _isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    final controller = _controller;
    if (controller == null) return true;
    if (await controller.canGoBack()) {
      await controller.goBack();
      return false;
    }
    return true;
  }

  void _retry() {
    _tearDownWebView(notify: true);
    _ensureWebView();
  }

  Widget _buildLoader(BuildContext context) {
    return Center(
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
  }

  @override
  Widget build(BuildContext context) {
    final loader = _buildLoader(context);

    if (!widget.isActive) {
      return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: SafeArea(child: loader),
      );
    }

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

    final controller = _controller;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: SafeArea(
          child: Stack(
            children: [
              if (controller != null)
                KeyedSubtree(
                  key: _webViewKey,
                  child: WebViewWidget(controller: controller),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: (_isLoading || controller == null)
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
