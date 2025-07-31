import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// Trackers
import 'trackers/interaction/tap_tracker.dart';
import 'trackers/interaction/swipe_tracker.dart';
import 'trackers/interaction/input_tracker.dart';
import 'trackers/location_tracker.dart';
import 'trackers/navigation_logger.dart';

// Session & Utils
import 'analytics/session_tracker.dart';
import 'device/device_info_logger.dart';
import '../storage/export_manager.dart';
import 'detectors/screen_recording_detector.dart';

class PhishSafeTrackerManager {
  // ✅ Singleton pattern
  static final PhishSafeTrackerManager _instance = PhishSafeTrackerManager._internal();
  factory PhishSafeTrackerManager() => _instance;
  PhishSafeTrackerManager._internal();

  // Trackers
  final TapTracker _tapTracker = TapTracker();
  final SwipeTracker _swipeTracker = SwipeTracker();
  final NavigationLogger _navLogger = NavigationLogger();
  final LocationTracker _locationTracker = LocationTracker();
  final SessionTracker _sessionTracker = SessionTracker();
  final DeviceInfoLogger _deviceLogger = DeviceInfoLogger();
  final ExportManager _exportManager = ExportManager();
  final InputTracker _inputTracker = InputTracker();

  final Map<String, int> _screenDurations = {};
  Timer? _screenRecordingTimer;
  bool _screenRecordingDetected = false;
  BuildContext? _context;

  // 🔌 Provide context to show dialogs
  void setContext(BuildContext context) {
    _context = context;
  }

  // 🎬 Start a new session
  void startSession() {
    _tapTracker.reset();
    _swipeTracker.reset();
    _navLogger.reset();
    _sessionTracker.startSession();
    _inputTracker.reset();
    _inputTracker.markLogin(); // ✅ Mark login time
    _screenRecordingDetected = false;
    _screenDurations.clear();

    print("✅ PhishSafe session started");

    _screenRecordingTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      final isRecording = await ScreenRecordingDetector().isScreenRecording();
      if (isRecording && !_screenRecordingDetected) {
        _screenRecordingDetected = true;
        print("🚨 Screen recording detected");

        if (_context != null) {
          showDialog(
            context: _context!,
            builder: (ctx) => AlertDialog(
              title: Text("⚠️ Security Warning"),
              content: Text("Screen recording is active. Please disable it to protect your banking session."),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  // ⏱️ Keep track of screen usage
  void recordScreenDuration(String screen, int seconds) {
    _screenDurations[screen] = (_screenDurations[screen] ?? 0) + seconds;
    print("📺 Screen duration recorded: $screen → $seconds seconds");
  }

  // 👆 Interaction tracking
  void onTap(String screen) => _tapTracker.recordTap(screenName: screen);
  void onSwipeStart(double pos) => _swipeTracker.startSwipe(pos);
  void onSwipeEnd(double pos) => _swipeTracker.endSwipe(pos);
  void onScreenVisited(String screen) => _navLogger.logVisit(screen);

  // 💰 Record transaction amount
  void recordTransactionAmount(String amount) {
    _inputTracker.setTransactionAmount(amount);
    print("💰 Transaction amount tracked: $amount");
  }

  // 🧨 Mark FD as broken
  void recordFDBroken() {
    _inputTracker.markFDBroken();
    print("🧨 FD broken marked");
  }

  // 💳 Mark loan as taken
  void recordLoanTaken() {
    _inputTracker.markLoanTaken();
    print("📋 Loan application recorded");
  }

  // 📤 End session and export to JSON
  Future<void> endSessionAndExport() async {
    _sessionTracker.endSession();
    _screenRecordingTimer?.cancel();
    _screenRecordingTimer = null;

    final Position? location = await _locationTracker.getCurrentLocation();
    final deviceInfo = await _deviceLogger.getDeviceInfo();
    final sessionDuration = _sessionTracker.sessionDuration?.inSeconds ?? 0;

    final allTapEvents = _tapTracker.getTapEvents();
    final allSwipeEvents = _swipeTracker.getSwipeEvents();
    final screenVisits = _navLogger.logs;

    // ⛓️ Enrich tap/swipe into screen visits
    final enrichedScreenVisits = screenVisits.map((visit) {
      final screenName = visit['screen'];
      final visitTime = DateTime.tryParse(visit['timestamp'] ?? '');

      final relatedTaps = allTapEvents.where((tap) {
        final tapTime = DateTime.tryParse(tap['timestamp']);
        if (tapTime == null || visitTime == null) return false;
        return tap['screen'] == screenName && (tapTime.difference(visitTime).inSeconds.abs() <= 30);
      }).toList();

      final relatedSwipes = allSwipeEvents.where((swipe) {
        final swipeTime = DateTime.tryParse(swipe['timestamp']);
        if (swipeTime == null || visitTime == null) return false;
        return (swipeTime.difference(visitTime).inSeconds.abs() <= 30);
      }).toList();

      return {
        ...visit,
        'tap_events': relatedTaps,
        'swipe_events': relatedSwipes,
      };
    }).toList();

    // 📦 Assemble session log
    final sessionData = {
      'session': {
        'start': _sessionTracker.startTimestamp,
        'end': _sessionTracker.endTimestamp,
        'duration_seconds': sessionDuration,
      },
      'device': deviceInfo,
      'location': location != null
          ? {'latitude': location.latitude, 'longitude': location.longitude}
          : 'Location unavailable',
      'tap_durations_ms': _tapTracker.getTapDurations(),
      'tap_events': allTapEvents,
      'swipe_events': allSwipeEvents,
      'screens_visited': enrichedScreenVisits,
      'screen_durations': _screenDurations,
      'screen_recording_detected': _screenRecordingDetected,

      // ✅ Tracked input summary + timing
      'session_input': {
        'transaction_amount': _inputTracker.getTransactionAmount(),
        'fd_broken': _inputTracker.isFDBroken,
        'loan_taken': _inputTracker.isLoanTaken,
        'time_from_login_to_fd': _inputTracker.timeFromLoginToFD?.inSeconds,
        'time_from_login_to_loan': _inputTracker.timeFromLoginToLoan?.inSeconds,
        'time_between_fd_and_loan': _inputTracker.timeBetweenFDAndLoan?.inSeconds,
      },
    };

    // 📝 Export to JSON
    await _exportManager.exportToJson(sessionData, 'session_log');
    print("📁 Session exported");
  }
}