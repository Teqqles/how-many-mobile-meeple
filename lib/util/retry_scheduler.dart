import 'dart:async';

/// Holds a single pending delayed action, replacing any prior one. Wraps the
/// cancel-old-timer/arm-new-one pattern. Owners must [cancel] on dispose.
class RetryScheduler {
  Timer? _timer;

  bool get isActive => _timer?.isActive ?? false;

  void schedule(Duration delay, void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();
}
