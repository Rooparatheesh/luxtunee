// lib/presentation/screens/main_scaffold.dart

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../widgets/player/mini_player.dart';
import 'explore/explore_screen.dart';
import 'settings/settings_screen.dart';
import 'home/home_screen.dart';

import 'home/dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/party_provider.dart';
import 'playlists/playlists_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0; // Default to Home tab

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider = context.read<PlayerProvider>();
      context.read<PartyProvider>().attachPlayer(playerProvider);
    });
  }

  final List<Widget> _pages = [
    const DashboardScreen(), // Home screen with both online and offline
    const ExploreScreen(), // Search/Explore
    const PlaylistsScreen(), // Dedicated Playlists tab
    const SettingsScreen(),
    const HomeScreen(), // Using HomeScreen as the Library
  ];

  @override
  Widget build(BuildContext context) {
    final partyProvider = context.watch<PartyProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              partyProvider.currentRoomCode != null ? Icons.podcasts_rounded : Icons.cell_tower_rounded,
              color: partyProvider.currentRoomCode != null ? Colors.greenAccent : Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _showPartyDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
          borderRadius: const BorderRadius.only(
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
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: AppColors.textMuted,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: AppTypography.label(
              size: 10,
              color: Theme.of(context).colorScheme.primary,
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
              _buildNavItem(Icons.queue_music_rounded, 'Playlists', 2),
              _buildNavItem(Icons.settings_rounded, 'Settings', 3),
              _buildNavItem(Icons.library_music_rounded, 'Library', 4),
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

  void _showPartyDialog(BuildContext context) {
    final partyProvider = context.read<PartyProvider>();
    final joinCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<PartyProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Party Mode',
                style: AppTypography.display(size: 20, weight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.currentRoomCode != null) ...[
                    Text(
                      provider.isHost ? 'You are hosting:' : 'You joined:',
                      style: AppTypography.label(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.currentRoomCode!,
                      style: AppTypography.display(size: 32, weight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        provider.leaveParty();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Leave Party', style: TextStyle(color: Colors.white)),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () async {
                        final code = await provider.startParty();
                        if (context.mounted) {
                          if (code != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Party Room Created! Share your code.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to create room. Please check your network.')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Start a Party', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                    ),
                    const SizedBox(height: 16),
                    Text('OR', style: AppTypography.label(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: joinCodeController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit code',
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final code = joinCodeController.text.trim();
                        if (code.isNotEmpty) {
                          final success = await provider.joinParty(code);
                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Successfully joined room $code!')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Room not found.')),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.libraryPillBg,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Join Party', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
