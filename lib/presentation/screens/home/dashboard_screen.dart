import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.libraryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Good Morning',
                style: AppTypography.display(
                  size: 28,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to LuxTune',
                style: AppTypography.body(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              
              // Placeholders for content
              _buildSectionTitle('Recently Played'),
              const SizedBox(height: 16),
              _buildPlaceholderCards(),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Your Mixes'),
              const SizedBox(height: 16),
              _buildPlaceholderCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.display(
        size: 20,
        weight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildPlaceholderCards() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.librarySurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.music_note_rounded, size: 48, color: AppColors.textMuted),
            ),
          );
        },
      ),
    );
  }
}
