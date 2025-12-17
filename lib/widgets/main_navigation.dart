import 'dart:async';
import 'package:app_clubee/screens/discover_screen.dart';
import 'package:flutter/material.dart';

import '../screens/account_screen.dart';
import '../screens/home_screen.dart';
import '../screens/news_screen.dart';
import '../services/deep_link_service.dart';
import '../services/logging_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final DeepLinkService _deepLinkService = DeepLinkService.instance;
  final LoggingService _log = LoggingService.instance;
  StreamSubscription<String>? _deepLinkSubscription;

  static const int accountIndex = 3;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  void _initializeDeepLinks() {
    // Verificar deep link pendente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingDeepLink();
    });

    // Escutar novos deep links
    _deepLinkSubscription = _deepLinkService.onDeepLink.listen((link) {
      _log.info('🔗 New deep link received in MainNavigation: $link');
      _processDeepLink(link);
    });
  }

  void _checkPendingDeepLink() {
    final pendingLink = _deepLinkService.pendingDeepLink;
    if (pendingLink != null) {
      _log.info('🔗 Processing pending deep link: $pendingLink');
      _processDeepLink(pendingLink);
      _deepLinkService.clearPendingDeepLink();
    }
  }

  void _processDeepLink(String link) {
    final info = _deepLinkService.parseDeepLink(link);

    if (info == null) {
      _log.warning('Failed to parse deep link: $link');
      return;
    }

    _log.success('Deep link parsed: ${info.toString()}');

    // Aguardar frame para garantir que a tela está montada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (info.type) {
        case DeepLinkType.profile:
          _onTabTapped(accountIndex);
          break;
        case DeepLinkType.home:
          _onTabTapped(0);
          break;
        default:
          // Outros tipos serão processados pela HomeScreen
          _onTabTapped(0);
          break;
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  late final List<Widget> _screens = [
    HomeScreen(onNavigateToAccount: () => _onTabTapped(accountIndex)),
    DiscoverScreen(),
    NewsScreen(),
    AccountScreen(),
  ];

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      _onTabTapped(0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Antes: onWillPop()
          final shouldPop = _onWillPop();

          shouldPop.then((value) {
            if (value) Navigator.of(context).maybePop();
          });
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          // Se quiser desativar swipe, descomente:
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_sharp),
              label: 'Descubra',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Notícias',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Conta',
            ),
          ],
        ),
      ),
    );
  }
}
