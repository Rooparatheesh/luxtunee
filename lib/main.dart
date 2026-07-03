// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:luxtunee/theme/app_theme.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'data/network/youtube/youtube_service.dart';
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

class LuxTuneApp extends StatefulWidget {
  const LuxTuneApp({super.key});

  @override
  State<LuxTuneApp> createState() => _LuxTuneAppState();
}

class _LuxTuneAppState extends State<LuxTuneApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial app link: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }

  void _handleDeepLink(Uri uri) async {
    String? videoId;
    if (uri.host.contains('youtube.com')) {
      videoId = uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    if (videoId != null && videoId.isNotEmpty) {
      try {
        final ytService = YoutubeService();
        final track = await ytService.getTrackFromId(videoId);
        if (mounted) {
          context.read<PlayerProvider>().playTrack(track);
        }
      } catch (e) {
        debugPrint('Failed to handle youtube link: $e');
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

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
