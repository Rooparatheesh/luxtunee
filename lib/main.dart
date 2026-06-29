// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:luxtunee/theme/app_theme.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'providers/player_provider.dart';
import 'providers/explore_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/party_provider.dart';
import 'providers/playlist_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.luxtunee.channel.audio',
    androidNotificationChannelName: 'LuxTune Playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/ic_notification',
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bottomNavBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => ExploreProvider()),
        ChangeNotifierProvider(create: (_) => PartyProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
      ],
      child: const LuxTuneApp(),
    ),
  );
}

class LuxTuneApp extends StatelessWidget {
  const LuxTuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return MaterialApp(
      title: 'LuxTune',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const OnboardingScreen(),
    );
  }
}
