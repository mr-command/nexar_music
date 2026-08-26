import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'screens/home_screen.dart';
import 'services/audio_handler.dart';
import 'services/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // The media session (background playback + notification) must exist before
  // the first track is opened, so build it ahead of the widget tree.
  final player = Player();
  final handler = await NexarAudioHandler.init(player);

  runApp(
    ProviderScope(
      overrides: [
        playerProvider.overrideWithValue(player),
        audioHandlerProvider.overrideWithValue(handler),
      ],
      child: const NexarApp(),
    ),
  );
}

class NexarApp extends StatelessWidget {
  const NexarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
        ),
        fontFamilyFallback: const ['Segoe UI', 'Ubuntu', 'Roboto'],
      ),
      home: const HomeScreen(),
    );
  }
}
