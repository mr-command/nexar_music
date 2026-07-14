import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

Widget liquidproccesbar(Player player){
  return StreamBuilder<Duration>(
    stream: player.stream.position,
    builder: (context, positionSnapshot) {
      return StreamBuilder<Duration>(
        stream: player.stream.duration,
        builder: (context, durationSnapshot) {
          return Container(
            width: 300,
            height: 50,
            child: ProgressBar(
              baseBarColor: Colors.grey[300],
              progressBarColor: Colors.white,
              barHeight: 6,
              thumbColor: Colors.white,
              timeLabelType: TimeLabelType.totalTime,
              barCapShape: BarCapShape.round,

              progress: positionSnapshot.data ?? Duration.zero,
              total: durationSnapshot.data ?? Duration.zero,
              onSeek: player.seek,
            ),
          );
        },
      );
    },
  );
}