class TapTracker {
  final List<int> _tapDurations = [];

  DateTime? _lastTap;

  final List<Map<String, dynamic>> _tapEvents = [];

  void recordTap({String? screenName}) {
    final now = DateTime.now();

    print("🧠 Recording tap on $screenName at $now");

    if (_lastTap != null) {
      final diff = now.difference(_lastTap!).inMilliseconds;
      _tapDurations.add(diff);
    }

    _tapEvents.add({
      'timestamp': now.toIso8601String(),
      'screen': screenName ?? 'Unknown',
    });

    _lastTap = now;
  }


  List<int> getTapDurations() => List.unmodifiable(_tapDurations);

  List<Map<String, dynamic>> getTapEvents() => List.unmodifiable(_tapEvents);

  void reset() {
    _lastTap = null;
    _tapDurations.clear();
    _tapEvents.clear();
  }
}
