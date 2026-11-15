import 'dart:async';

/// Debounces repeated calls: each call cancels the previous pending action
/// and schedules the new action to run after the configured quiet time.
class Debouncer {
  /// Creates a debouncer that waits [duration] of quiet time before firing;
  /// a typical value for a search box is 300 ms.
  Debouncer(this.duration);

  /// Quiet time that must elapse after the last call before the pending
  /// callback runs.
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
