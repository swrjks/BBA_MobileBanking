import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
import 'engine/trust_score_engine.dart';

class PhishSafeTrackerManager {
  static final PhishSafeTrackerManager _instance = PhishSafeTrackerManager._internal();
  factory PhishSafeTrackerManager() => _instance;
  PhishSafeTrackerManager._internal();

  final TapTracker _tapTracker = TapTracker();
  final SwipeTracker _swipeTracker = SwipeTracker();
  final NavigationLogger _navLogger = NavigationLogger();
  final LocationTracker _locationTracker = LocationTracker();
  final SessionTracker _sessionTracker = SessionTracker();
  final DeviceInfoLogger _deviceLogger = DeviceInfoLogger();
  final ExportManager _exportManager = ExportManager();
  final PhishSafeTrustScoreEngine _trustEngine = PhishSafeTrustScoreEngine();
  final InputTracker _inputTracker = InputTracker();

  final Map<String, int> _screenDurations = {};
  Timer? _screenRecordingTimer;
  Timer? _liveTrustMonitorTimer;
  Timer? _inactivityTimer;
  bool _screenRecordingDetected = false;
  BuildContext? _context;
  DateTime _lastInteraction = DateTime.now();

  // Configuration
  static const _logoutTimeout = 15; // Seconds of inactivity to logout
  static const _warningTimeout = 5; // Seconds of inactivity to start penalty
  static const _highValueAmount = 10000.0; // Amount that triggers security question

  void setContext(BuildContext context) {
    _context = context;
  }

  void startSession() {
    _tapTracker.reset();
    _swipeTracker.reset();
    _navLogger.reset();
    _sessionTracker.startSession();
    _inputTracker.reset();
    _screenRecordingDetected = false;
    _screenDurations.clear();
    _lastInteraction = DateTime.now();
    _trustEngine.resetScore();

    if (kDebugMode) {
      print("✅ PhishSafe session started");
    }

    // Start screen recording detection
    _screenRecordingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final isRecording = await ScreenRecordingDetector().isScreenRecording();
      if (isRecording && !_screenRecordingDetected) {
        _screenRecordingDetected = true;
        if (kDebugMode) {
          print("🚨 Screen recording detected");
        }
        _showScreenRecordingWarning();
        _trustEngine.applyPenalty(20.0, 'Screen recording detected');
      }
    });

    // Start inactivity monitoring
    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final idleSeconds = DateTime.now().difference(_lastInteraction).inSeconds;
      if (idleSeconds >= _warningTimeout) {
        final penalty = 5.0 * (idleSeconds - _warningTimeout + 1);
        _trustEngine.applyPenalty(penalty, 'Inactivity penalty');
      }

      if (idleSeconds >= _logoutTimeout) {
        _trustEngine.applyPenalty(100.0, 'Auto-logout due to inactivity');
        _logoutUser();
      }
    });

    // Start live trust monitoring
    startLiveTrustMonitoring();
  }

  void startLiveTrustMonitoring() {
    _liveTrustMonitorTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final score = _trustEngine.currentScore;
        final action = _trustEngine.recommendedAction;

        if (kDebugMode) {
          print("🧠 Live Trust Score: ${score.toStringAsFixed(1)} → Action: $action");
        }

        if (action == 'LOG_OUT') {
          _showThreatPopup(score, 'LOG_OUT');
          _liveTrustMonitorTimer?.cancel();
        } else if (action == 'ASK_SECURITY_QUESTION') {
          _showThreatPopup(score, 'ASK_SECURITY_QUESTION');
        }
      } catch (e) {
        if (kDebugMode) {
          print("⚠️ Live trust monitor failed: $e");
        }
      }
    });
  }

  void stopLiveTrustMonitoring() {
    _liveTrustMonitorTimer?.cancel();
    _liveTrustMonitorTimer = null;
  }

  void _showScreenRecordingWarning() {
    if (_context == null) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ Security Warning"),
        content: const Text("Screen recording is active. Please disable it to protect your banking session."),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showThreatPopup(double score, String actionType) {
    if (_context == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(_context!);
    TextEditingController controller = TextEditingController();

    String title;
    String message;
    List<Widget> actions = [];

    final scoreDisplay = score.toStringAsFixed(1);

    switch (actionType) {
      case "LOG_OUT":
        title = "🚫 Session Terminated";
        message = "Your trust score is too low ($scoreDisplay).\n"
            "This session is marked as highly suspicious and you will be logged out for safety.";
        actions.add(
          TextButton(
            onPressed: () {
              Navigator.of(_context!).pop();
              _logoutUser();
            },
            child: const Text("OK"),
          ),
        );
        break;

      case "ASK_SECURITY_QUESTION":
        title = "🔒 Additional Verification Required";
        message = "For your security (Trust Score: $scoreDisplay), please answer your security question:\n\n"
            "What was the name of your first pet?";
        actions.addAll([
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Security Answer"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _trustEngine.resetScore(); // Reset score after successful verification
                scaffoldMessenger.showSnackBar(const SnackBar(
                  content: Text("✅ Verification complete"),
                  backgroundColor: Colors.green,
                ));
                Navigator.of(_context!).pop();
              } else {
                scaffoldMessenger.showSnackBar(const SnackBar(
                  content: Text("Please provide an answer"),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: const Text("Submit"),
          ),
        ]);
        break;

      default:
        return;
    }

    showDialog(
      context: _context!,
      barrierDismissible: actionType != "LOG_OUT",
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions,
      ),
    );
  }

  void _logoutUser() {
    if (kDebugMode) {
      print("🔒 Logging out user...");
    }
    endSessionAndExport();
    if (_context != null) {
      Navigator.of(_context!).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void recordUserInteraction() {
    _lastInteraction = DateTime.now();
    if (kDebugMode) {
      print("👆 User interaction at $_lastInteraction");
    }
  }

  void recordScreenDuration(String screen, int seconds) {
    _screenDurations[screen] = (_screenDurations[screen] ?? 0) + seconds;
    if (kDebugMode) {
      print("📺 Screen duration recorded: $screen → $seconds seconds");
    }
  }

  void onTap(String screen) {
    _tapTracker.recordTap(screenName: screen);
    recordUserInteraction();
    _trustEngine.onTap(); // Notify trust engine about the tap
  }

  void onSwipeStart(double pos) {
    _swipeTracker.startSwipe(pos);
    recordUserInteraction();
  }

  void onSwipeEnd(double pos) {
    _swipeTracker.endSwipe(pos);
    recordUserInteraction();
  }

  void onScreenVisited(String screen) {
    _navLogger.logVisit(screen);
    recordUserInteraction();
  }

  void recordTransactionAmount(String amount) {
    final amountValue = double.tryParse(amount) ?? 0.0;
    _inputTracker.setTransactionAmount(amount);
    _trustEngine.setTransactionAmount(amountValue);

    if (kDebugMode) {
      print("💰 Transaction amount tracked: $amount");
    }

    if (amountValue >= _highValueAmount) {
      _showThreatPopup(_trustEngine.currentScore, 'ASK_SECURITY_QUESTION');
    }
  }

  void recordFDBroken() {
    _inputTracker.markFDBroken();
    _trustEngine.applyPenalty(15.0, 'FD broken');
    if (kDebugMode) {
      print("🧨 FD broken marked");
    }
  }

  void recordLoanTaken() {
    _inputTracker.markLoanTaken();
    _trustEngine.applyPenalty(10.0, 'Loan application');
    if (kDebugMode) {
      print("📋 Loan application recorded");
    }
  }

  Future<void> endSessionAndExport() async {
    _sessionTracker.endSession();
    _screenRecordingTimer?.cancel();
    _screenRecordingTimer = null;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    stopLiveTrustMonitoring();

    final Position? location = await _locationTracker.getCurrentLocation();
    final deviceInfo = await _deviceLogger.getDeviceInfo();
    final sessionDuration = _sessionTracker.sessionDuration?.inSeconds ?? 0;

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
      'tap_events': _tapTracker.getTapEvents(),
      'swipe_events': _swipeTracker.getSwipeEvents(),
      'screens_visited': _navLogger.logs,
      'screen_durations': _screenDurations,
      'screen_recording_detected': _screenRecordingDetected,
      'session_input': {
        'transaction_amount': _inputTracker.getTransactionAmount(),
        'fd_broken': _inputTracker.isFDBroken,
        'loan_taken': _inputTracker.isLoanTaken,
      },
      'trust_score': _trustEngine.currentScore,
      'final_action': _trustEngine.recommendedAction,
    };

    await _exportManager.exportToJson(sessionData, 'session_log');
    if (kDebugMode) {
      print("📁 Session exported");
    }
  }
}