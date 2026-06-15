// lib/presentation/screens/main_scaffold.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/player/mini_player.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 3; // Default to Library tab as requested

  final List<Widget> _pages = [
    _PlaceholderPage(title: 'Home'),
    const ExploreScreen(), // Online music streaming screen
    _PlaceholderPage(title: 'Search'),
    const HomeScreen(), // Using HomeScreen as the Library
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.libraryBackground,
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
        decoration: const BoxDecoration(
          color: AppColors.bottomNavBg,
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
            backgroundColor: AppColors.bottomNavBg,
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
              _buildNavItem(Icons.search_rounded, 'Search', 2),
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

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: AppTypography.heading(color: AppColors.textMuted),
      ),
    );
  }
}
