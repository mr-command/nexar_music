import 'package:audio_metadata_reader/audio_metadata_reader.dart';

class Song{
  final String path;
  final AudioMetadata metadata;

  Song({
    required this.path,
    required this.metadata
  });
}