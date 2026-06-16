// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _navidromeUrlCtrl = TextEditingController();
  final _navidromeUserCtrl = TextEditingController();
  final _navidromePassCtrl = TextEditingController();

  final _jellyfinUrlCtrl = TextEditingController();
  final _jellyfinUserCtrl = TextEditingController();
  final _jellyfinPassCtrl = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _navidromeUrlCtrl.text = prefs.getString('navidrome_url') ?? '';
      _navidromeUserCtrl.text = prefs.getString('navidrome_user') ?? '';
      _navidromePassCtrl.text = prefs.getString('navidrome_pass') ?? '';

      _jellyfinUrlCtrl.text = prefs.getString('jellyfin_url') ?? '';
      _jellyfinUserCtrl.text = prefs.getString('jellyfin_user') ?? '';
      _jellyfinPassCtrl.text = prefs.getString('jellyfin_pass') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('navidrome_url', _navidromeUrlCtrl.text.trim());
    await prefs.setString('navidrome_user', _navidromeUserCtrl.text.trim());
    await prefs.setString('navidrome_pass', _navidromePassCtrl.text.trim());

    await prefs.setString('jellyfin_url', _jellyfinUrlCtrl.text.trim());
    await prefs.setString('jellyfin_user', _jellyfinUserCtrl.text.trim());
    await prefs.setString('jellyfin_pass', _jellyfinPassCtrl.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved', style: AppTypography.body(color: AppColors.white)),
          backgroundColor: AppColors.libraryTextGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _navidromeUrlCtrl.dispose();
    _navidromeUserCtrl.dispose();
    _navidromePassCtrl.dispose();
    _jellyfinUrlCtrl.dispose();
    _jellyfinUserCtrl.dispose();
    _jellyfinPassCtrl.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: AppTypography.heading(size: 20, color: AppColors.libraryTextGreen),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: AppTypography.body(color: AppColors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.body(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.librarySurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.libraryTextGreen),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.libraryBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.libraryTextGreen)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.libraryBackground,
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
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSectionHeader('Navidrome Server'),
              _buildTextField(_navidromeUrlCtrl, 'Server URL (e.g. http://192.168.1.100:4533)'),
              _buildTextField(_navidromeUserCtrl, 'Username'),
              _buildTextField(_navidromePassCtrl, 'Password', obscure: true),

              _buildSectionHeader('Jellyfin Server'),
              _buildTextField(_jellyfinUrlCtrl, 'Server URL (e.g. http://192.168.1.100:8096)'),
              _buildTextField(_jellyfinUserCtrl, 'Username'),
              _buildTextField(_jellyfinPassCtrl, 'Password', obscure: true),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.libraryPillActiveBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text(
                    'Save Settings',
                    style: AppTypography.body(weight: FontWeight.w600, color: AppColors.white),
                  ),
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
