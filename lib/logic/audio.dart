import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MusicService extends BaseAudioHandler {
  late AudioPlayer _player;
  late StreamSubscription _playerSubscription;
  final Completer<void> _initializationCompleter = Completer<void>();
  bool _isInitialized = false;

  // سازنده برای مقداردهی اولیه
  MusicService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _player = AudioPlayer();
      
      // تنظیم منبع صوتی
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse('https://sv.musicc.ir/mp3s/2025-12-08/6936c4a25d8af-yeh-moshteh-khak-habib(320).mp3')),
      );
      
      // تنظیم اطلاعات آهنگ
      final duration = await _player.duration;
      mediaItem.add(MediaItem(
        id: '1',
        title: 'یه مشت خاک',
        artist: 'حبیب',
        album: 'آلبوم حبیب',
        duration: duration,
      ));
      
      // شنود تغییرات وضعیت پخش
      _playerSubscription = _player.playbackEventStream.listen((event) {
        _broadcastState();
      });
      
      _broadcastState();
      _isInitialized = true;
      _initializationCompleter.complete();
      
      print('Music service initialized successfully');
    } catch (e) {
      print('Error initializing music service: $e');
      _initializationCompleter.completeError(e);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializationCompleter.future;
    }
  }

  void _broadcastState() {
    if (!_isInitialized) return;
    
    try {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: {
          // حذف seekTo چون وجود ندارد
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: _getProcessingState(),
        playing: _player.playing,
        updatePosition: _player.position,
        speed: _player.speed,
      ));
      
      // به‌روزرسانی position به صورت مداوم
      if (_player.playing) {
        Future.delayed(Duration(milliseconds: 500), _broadcastState);
      }
    } catch (e) {
      print('Error broadcasting state: $e');
    }
  }

  AudioProcessingState _getProcessingState() {
    if (!_isInitialized) return AudioProcessingState.idle;
    if (_player.playing) return AudioProcessingState.ready;
    if (_player.processingState == ProcessingState.loading) 
      return AudioProcessingState.loading;
    if (_player.processingState == ProcessingState.buffering) 
      return AudioProcessingState.buffering;
    return AudioProcessingState.idle;
  }

  @override
  Future<void> play() async {
    await _ensureInitialized();
    try {
      await _player.play();
      print('Playback started');
    } catch (e) {
      print('Error playing: $e');
    }
  }

  @override
  Future<void> pause() async {
    await _ensureInitialized();
    try {
      await _player.pause();
      print('Playback paused');
    } catch (e) {
      print('Error pausing: $e');
    }
  }

  @override
  Future<void> stop() async {
    await _ensureInitialized();
    try {
      await _player.stop();
      print('Playback stopped');
    } catch (e) {
      print('Error stopping: $e');
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _ensureInitialized();
    try {
      await _player.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    await _ensureInitialized();
    try {
      // منطق آهنگ بعدی
      await _player.seek(Duration.zero);
    } catch (e) {
      print('Error skipping to next: $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    await _ensureInitialized();
    try {
      // منطق آهنگ قبلی
      await _player.seek(Duration.zero);
    } catch (e) {
      print('Error skipping to previous: $e');
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _ensureInitialized();
    try {
      await _player.setSpeed(speed);
    } catch (e) {
      print('Error setting speed: $e');
    }
  }

  // حذف onDestroy و جایگزینی با stop
  Future<void> dispose() async {
    if (_isInitialized) {
      await _playerSubscription.cancel();
      await _player.dispose();
    }
  }
}