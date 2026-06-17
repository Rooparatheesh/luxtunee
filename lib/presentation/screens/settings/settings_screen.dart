import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: AppTypography.display(
                  size: 28,
                  weight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: AppTypography.body(color: Theme.of(context).colorScheme.onSurface, weight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Toggle dark and light theme',
                    style: AppTypography.label(color: AppColors.textMuted),
                  ),
                  value: isDark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              
              const SizedBox(height: 100), // Bottom padding for mini player
            ],
          ),
        ),
      ),
    );
  }
}
