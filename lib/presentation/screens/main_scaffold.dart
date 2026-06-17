// lib/presentation/screens/main_scaffold.dart

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../widgets/player/mini_player.dart';
import 'explore/explore_screen.dart';
import 'settings/settings_screen.dart';
import 'home/home_screen.dart';

import 'home/dashboard_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0; // Default to Home tab

  final List<Widget> _pages = [
    const DashboardScreen(), // Home screen with both online and offline
    const ExploreScreen(), // Search/Explore
    const SettingsScreen(),
    const HomeScreen(), // Using HomeScreen as the Library
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main content
          _pages[_currentIndex],
          
          // Mini Player overlay sitting just above the bottom nav
          const Positioned(
            left: 16,
            right: 16,
            bottom: 0, 
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Theme.of(context).cardColor,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.libraryTextGreen,
            unselectedItemColor: AppColors.textMuted,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: AppTypography.label(
              size: 10,
              color: AppColors.libraryTextGreen,
              weight: FontWeight.w700,
            ),
            unselectedLabelStyle: AppTypography.label(
              size: 10,
              color: AppColors.textMuted,
              weight: FontWeight.w500,
            ),
            items: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.explore_rounded, 'Explore', 1),
              _buildNavItem(Icons.settings_rounded, 'Settings', 2),
              _buildNavItem(Icons.library_music_rounded, 'Library', 3),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.libraryPillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 24),
      ),
      label: label,
    );
  }
}
