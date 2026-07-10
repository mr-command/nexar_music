import 'package:audio_metadata_reader/audio_metadata_reader.dart';

class Song{
  final int id;
  final String path;
  final AudioMetadata metadata;

  Song({
    required this.id,
    required this.path,
    required this.metadata
  });
}