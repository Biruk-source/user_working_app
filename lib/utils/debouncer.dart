import 'dart:async';
import 'dart:ui';

/// A utility class to debounce actions, preventing them from being executed too frequently.
class Debouncer {
  Timer? _timer;

  /// Runs the provided callback after a delay, canceling any previous pending execution.
  /// 
  /// Args:
  /// - `callback`: The function to be executed after the delay.
  /// - `delay`: The duration to wait before executing the callback.
  void run(VoidCallback callback, {Duration delay = const Duration(milliseconds: 2)}) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Disposes of the timer to prevent memory leaks.
  void dispose() {
    _timer?.cancel();
  }
}