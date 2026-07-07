import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/services/Audio/AudioServices.dart';
import 'package:nexar_app/services/DataBase/models.dart';

final playerProvider = Provider<Player>((ref) {
  final player = Player();

  ref.onDispose(player.dispose);

  return player;
});

final audioServiceProvider = Provider<AudioServices>((ref) {
  return AudioServices(ref.watch(playerProvider));
});


final nowPlaying = StateProvider<Song?>(
  (ref) => null
);


