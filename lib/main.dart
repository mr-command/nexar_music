import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'components/design_system.dart';
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

class NexarApp extends ConsumerWidget {
  const NexarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStyle = ref.watch(themeProvider);
    const lightDesign = NeumorphismDesign();
    const darkDesign = LiquidGlassDesign();

    return MaterialApp(
      title: 'Nexar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: lightDesign.accent),
        scaffoldBackgroundColor: lightDesign.scaffoldBackground,
        fontFamilyFallback: const ['Segoe UI', 'Ubuntu', 'Roboto'],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkDesign.accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: darkDesign.scaffoldBackground,
        fontFamilyFallback: const ['Segoe UI', 'Ubuntu', 'Roboto'],
      ),
      themeMode:
          appStyle == AppStyle.dark ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
