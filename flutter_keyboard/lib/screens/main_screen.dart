import 'package:flutter/material.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';
import 'profiles_list_screen.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';
import '../config/app_theme.dart';
import '../config/app_haptics.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
            AppHaptics.selection();
          },
          children: const [
            ProfilesListScreen(),
            MyProfileContent(),
            DashboardScreen(),
            SubscriptionContent(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(
            top: BorderSide(color: AppColors.elevatedDark, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.people_outlined),
              selectedIcon: ShaderMask(
                shaderCallback: (bounds) => AppColors.buttonGradient.createShader(bounds),
                child: const Icon(Icons.people, color: Colors.white),
              ),
              label: 'Contatos',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outlined),
              selectedIcon: ShaderMask(
                shaderCallback: (bounds) => AppColors.buttonGradient.createShader(bounds),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              label: l10n.myProfileTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: ShaderMask(
                shaderCallback: (bounds) => AppColors.buttonGradient.createShader(bounds),
                child: const Icon(Icons.insights, color: Colors.white),
              ),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: const Icon(Icons.credit_card_outlined),
              selectedIcon: ShaderMask(
                shaderCallback: (bounds) => AppColors.buttonGradient.createShader(bounds),
                child: const Icon(Icons.credit_card, color: Colors.white),
              ),
              label: l10n.subscriptionTab,
            ),
          ],
        ),
      ),
    );
  }
}
