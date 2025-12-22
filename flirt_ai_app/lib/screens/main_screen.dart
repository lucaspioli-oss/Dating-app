import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'conversations_screen.dart';
import 'unified_analysis_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_sidebar.dart';
import '../config/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Ordem: Minha Conta, Primeira Mensagem, Conversas
  final List<Widget> _screens = [
    const ProfileScreen(),
    const UnifiedAnalysisScreen(),
    const ConversationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = kIsWeb && screenWidth > 800;

    if (isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Row(
        children: [
          // Sidebar
          AppSidebar(
            selectedIndex: _currentIndex,
            onItemSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          // Content
          Expanded(
            child: SafeArea(
              top: false,
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    // Para mobile, mantém a ordem original: Conversas, Análise, Perfil
    final mobileScreens = [
      const ConversationsScreen(),
      const UnifiedAnalysisScreen(),
      const ProfileScreen(),
    ];

    // Mapear índice do sidebar para índice mobile
    int mobileIndex;
    switch (_currentIndex) {
      case 0: // Minha Conta -> Perfil (index 2)
        mobileIndex = 2;
        break;
      case 1: // Primeira Mensagem -> Análise (index 1)
        mobileIndex = 1;
        break;
      case 2: // Conversas -> Conversas (index 0)
        mobileIndex = 0;
        break;
      default:
        mobileIndex = 0;
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: mobileIndex,
          children: mobileScreens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileIndex,
        onDestinationSelected: (index) {
          setState(() {
            // Mapear índice mobile para índice do sidebar
            switch (index) {
              case 0: // Conversas
                _currentIndex = 2;
                break;
              case 1: // Análise
                _currentIndex = 1;
                break;
              case 2: // Perfil
                _currentIndex = 0;
                break;
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Conversas',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Análise',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
