import 'dart:async';

/// Debounces repeated calls: each call cancels the previous pending action
/// and schedules [action] to run after [duration] of quiet time.
class Debouncer {
  Debouncer(this.duration);

  final Duration duration;
  Timer? _timer;

  /// Schedules [action] after [duration], cancelling any pending call.
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels the pending call, if any. Call from the owner's dispose().
  void cancel() {
    _timer?.cancel();
  }
}
