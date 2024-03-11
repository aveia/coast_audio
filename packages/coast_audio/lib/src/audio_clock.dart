import 'dart:async';

import 'audio_time.dart';

typedef AudioClockCallback = void Function(AudioClock clock);

abstract class AudioClock {
  AudioClock();

  bool get isStarted;

  AudioTime get elapsedTime;

  final callbacks = <AudioClockCallback>[];

  void start();

  void stop();
}

class AudioIntervalClock extends AudioClock {
  AudioIntervalClock(this.interval);

  Timer? _timer;
  final Stopwatch _watch = Stopwatch();

  final Duration interval;

  @override
  bool get isStarted => _timer != null;

  @override
  AudioTime get elapsedTime => AudioTime(_watch.elapsedMicroseconds / 1000.0 / 1000.0);

  @override
  void start() {
    if (_timer != null) {
      stop();
    }
    _watch.start();
    _timer = Timer.periodic(interval, (timer) {
      for (var f in callbacks) {
        f(this);
      }
    });
  }

  @override
  void stop() {
    _watch.stop();
    _timer?.cancel();
    _timer = null;
  }
}
