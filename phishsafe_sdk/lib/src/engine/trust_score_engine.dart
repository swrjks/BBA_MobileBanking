import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

class PhishSafeTrustScoreEngine {
  static final PhishSafeTrustScoreEngine _instance = PhishSafeTrustScoreEngine._internal();
  factory PhishSafeTrustScoreEngine() => _instance;
  PhishSafeTrustScoreEngine._internal();

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // Trust score management
  double _trustScore = 100.0;
  DateTime _lastInteraction = DateTime.now();
  Timer? _monitoringTimer;
  DateTime? _lastTapTime;
  DateTime? _lastSwipeTime;
  bool _isInTransactionFlow = false;

  // Interaction tracking
  final List<DateTime> _recentInteractions = [];
  final List<DateTime> _tapTimestamps = [];
  int _consecutiveFastTaps = 0;
  int _consecutiveSlowInteractions = 0;
  int _swipeCount = 0;
  int _tapCountInCurrentSecond = 0;
  double? _transactionAmount;
  bool _securityQuestionAsked = false;
  bool _otpRequested = false;
  bool _otpVerifiedInCurrentSession = false;

  // Popup management
  Function(String, String)? _showSecurityPopup; // Now accepts message and action type
  Function()? _logoutCallback;
  Function()? _onOtpRequired;
  Function()? _onSecurityQuestionRequired;

  // Configuration - Optimized values
  static const _debugMode = true;
  static const _maxTapsPerSecond = 6;       // Triggers OTP
  static const _minTapsPerInterval = 4;     // Less than 4 in 10 seconds is suspicious
  static const _minInteractionsPerMinute = 10; // Minimum normal interactions
  static const _slowInteractionThreshold = 3; // Seconds between interactions considered slow
  static const _evaluationWindow = 15;      // Seconds to evaluate patterns
  static const _logoutTimeout = 90;         // Seconds
  static const _inactivityWarning = 30;     // Seconds
  static const _highValueAmount = 9999.0;   // Large transaction threshold
  static const _fastTransactionThreshold = 5000.0;
  static const _swipeDetectionThreshold = 3; // Number of swipes to trigger analysis
  static const _warningTimeout = 10;        // Seconds before penalties
  static const _transactionOtpThreshold = 2000.0; // Amount above which OTP is required

  // Score thresholds
  static const _logoutThreshold = 20.0;
  static const _securityQuestionThreshold = 40.0;
  static const _otpThreshold = 60.0;
  static const _modelActivationThreshold = 30.0;

  // Initialize with UI callbacks
  void initialize({
    required Function(String, String) showPopup,
    required Function() logout,
    required Function() onOtpRequired,
    required Function() onSecurityQuestionRequired,
  }) {
    _showSecurityPopup = showPopup;
    _logoutCallback = logout;
    _onOtpRequired = onOtpRequired;
    _onSecurityQuestionRequired = onSecurityQuestionRequired;
    startMonitoring();
    if (_debugMode) print('Engine initialized with UI callbacks');
  }

  Future<void> _ensureModelLoaded() async {
    if (!_isModelLoaded) {
      try {
        _interpreter = await Interpreter.fromAsset(
            'assets/models/model.tflite',
            options: InterpreterOptions()..threads = 4);
        _isModelLoaded = true;
        if (_debugMode) print('Model loaded successfully');
      } catch (e) {
        if (_debugMode) print('Model load failed: ${e.toString()}');
      }
    }
  }

  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
    _monitoringTimer?.cancel();
  }

  // TRANSACTION FLOW MANAGEMENT =====================================

  void startTransactionFlow() {
    _isInTransactionFlow = true;
    _otpVerifiedInCurrentSession = false;
    if (_debugMode) print('🏦 Transaction flow started');
  }

  void completeTransactionFlow() {
    _isInTransactionFlow = false;
    if (_debugMode) print('✅ Transaction flow completed');
  }

  void setTransactionAmount(double amount, {bool isQuickPayment = false}) {
    _transactionAmount = amount;

    if (amount >= _highValueAmount) {
      applyPenalty(50.0, 'Very high value transaction (₹${amount.toStringAsFixed(2)})');
      _securityQuestionAsked = true;
      if (_debugMode) print('❗❗ VERY HIGH VALUE TRANSACTION DETECTED (₹$amount)');
      _triggerSecurityQuestion('High value transaction detected');
    }
    else if (isQuickPayment) {
      applyPenalty(15.0, 'Fast payment attempt (₹${amount.toStringAsFixed(2)})');
      if (_debugMode) print('⚡ Fast payment detected (₹$amount)');
      _triggerOtpRequest('Fast payment attempt detected');
    }
    else if (amount >= _fastTransactionThreshold) {
      applyPenalty(20.0, 'High value transaction (₹${amount.toStringAsFixed(2)})');
      if (_debugMode) print('⚠️ High value transaction (₹$amount)');
      if (amount >= _transactionOtpThreshold && !_otpVerifiedInCurrentSession) {
        _triggerOtpRequest('Transaction requires OTP verification');
      }
    }
    _checkAndTriggerPopup();
  }

  // INTERACTION TRACKING ============================================

  void onTap() {
    final now = DateTime.now();
    _recordInteraction(now, isTap: true);
    _recordTap(now);
    _updateLastInteraction(now);
    if (_debugMode) print('⬇️ Tap detected at $now');
    _checkAndTriggerPopup();
  }

  void onSwipe() {
    final now = DateTime.now();
    _recordInteraction(now, isSwipe: true);
    _updateLastInteraction(now);
    _swipeCount++;
    if (_debugMode) print('➡️ Swipe detected at $now');

    if (_swipeCount >= _swipeDetectionThreshold) {
      _analyzeSwipePatterns();
    }
    _checkAndTriggerPopup();
  }

  void _recordInteraction(DateTime timestamp, {bool isTap = false, bool isSwipe = false}) {
    if (_lastInteraction != null) {
      final gap = timestamp.difference(_lastInteraction!).inSeconds;

      if (gap >= _slowInteractionThreshold) {
        _consecutiveSlowInteractions++;
        _consecutiveFastTaps = 0;
        if (_debugMode) print('🐢 Slow interaction detected (${gap}s since last)');
      }
      else if (isTap && gap < 0.5) {
        _consecutiveFastTaps++;
        _consecutiveSlowInteractions = 0;
        if (_debugMode) print('⚡ Fast tap detected (${gap}s since last)');
      } else {
        _consecutiveFastTaps = 0;
        _consecutiveSlowInteractions = 0;
      }
    }

    if (isTap) _lastTapTime = timestamp;
    if (isSwipe) _lastSwipeTime = timestamp;

    _lastInteraction = timestamp;
    _recentInteractions.add(timestamp);
    _recentInteractions.removeWhere((ts) => timestamp.difference(ts).inSeconds > _evaluationWindow);

    _evaluateInteractionPatterns();
  }

  void _recordTap(DateTime timestamp) {
    _tapTimestamps.add(timestamp);
    _tapCountInCurrentSecond++;

    // Remove taps older than our evaluation window
    _tapTimestamps.removeWhere((ts) =>
    timestamp.difference(ts).inSeconds > _evaluationWindow);

    // Reset the per-second counter every second
    Timer(Duration(seconds: 1), () {
      _tapCountInCurrentSecond = 0;
    });

    _evaluateTapPatterns();
  }

  void _analyzeSwipePatterns() {
    if (_swipeCount > 5) {
      applyPenalty(15.0, 'Suspicious swipe pattern detected');
      if (_debugMode) print('⚠️ Suspicious swipe pattern detected ($_swipeCount swipes)');
    }
    _swipeCount = 0;
  }

  void _updateLastInteraction(DateTime timestamp) {
    _lastInteraction = timestamp;
    if (_securityQuestionAsked) {
      // After answering security question, reset score to 80 instead of 100
      _trustScore = max(80.0, _trustScore);
      _securityQuestionAsked = false;
      if (_debugMode) print('🔐 Security question answered - score reset to 80');
    } else if (_trustScore < 100) {
      _trustScore = min(_trustScore + 15.0, 100.0);
      if (_debugMode) print('🔄 Activity bonus: +15pts (Score: $_trustScore)');
    }
  }

  void _evaluateTapPatterns() {
    final now = DateTime.now();

    // 1. Check for too many taps in a short time (6+ taps in 1 second)
    if (_tapCountInCurrentSecond >= _maxTapsPerSecond) {
      applyPenalty(15.0, 'Excessive taps ($_tapCountInCurrentSecond taps in 1 second)');
      if (!_otpRequested) {
        _triggerOtpRequest('Too many taps detected');
      }
    }

    // 2. Check for too few taps in the evaluation window
    if (_tapTimestamps.isNotEmpty) {
      final windowDuration = now.difference(_tapTimestamps.first).inSeconds;
      if (windowDuration >= _warningTimeout &&
          _tapTimestamps.length < _minTapsPerInterval) {
        applyPenalty(10.0, 'Insufficient taps (${_tapTimestamps.length} taps in $windowDuration seconds)');
      }
    }
  }

  void _evaluateInteractionPatterns() {
    final now = DateTime.now();

    if (_consecutiveFastTaps >= 3) {
      applyPenalty(20.0, 'Rapid tap pattern detected');
      if (_debugMode) print('🚨 Rapid tap pattern detected ($_consecutiveFastTaps consecutive)');

      if (!_otpRequested) {
        _triggerOtpRequest('Rapid tap pattern detected');
      }
    }

    if (_consecutiveSlowInteractions >= 2) {
      applyPenalty(15.0, 'Suspicious slow interaction pattern');
      if (_debugMode) print('⚠️ Suspicious slow interactions detected ($_consecutiveSlowInteractions consecutive)');

      if (!_securityQuestionAsked) {
        _triggerSecurityQuestion('Suspicious activity detected');
      }
    }

    if (_recentInteractions.isNotEmpty) {
      final windowDuration = now.difference(_recentInteractions.first).inSeconds;
      final interactionsPerMinute = (_recentInteractions.length / windowDuration) * 60;

      if (windowDuration >= 30 && interactionsPerMinute < _minInteractionsPerMinute) {
        applyPenalty(10.0, 'Low activity detected (${interactionsPerMinute.toStringAsFixed(1)} interactions/min)');
      }
    }
  }

  void _evaluateUserBehavior() {
    final now = DateTime.now();
    final idleSeconds = now.difference(_lastInteraction!).inSeconds;

    // 3. Check for inactivity (10+ seconds)
    if (idleSeconds >= _warningTimeout) {
      // More gradual penalty - starts after 10 seconds, max 20 points
      final penaltyPoints = min(2.0 * (idleSeconds - _warningTimeout + 1), 20.0);
      applyPenalty(penaltyPoints, 'Inactivity penalty (${idleSeconds}s)');
    }

    if (idleSeconds >= _inactivityWarning) {
      final penaltyPoints = min(1.2 * pow((idleSeconds - _inactivityWarning + 1), 1.1).toDouble(), 25.0);
      applyPenalty(penaltyPoints, 'Inactivity (${idleSeconds}s)');
    }

    if (idleSeconds >= _logoutTimeout) {
      _trustScore = 0;
      if (_debugMode) print('🔴 Auto-logout due to inactivity');
      _triggerLogout();
    }

    if (idleSeconds > 10) {
      _consecutiveFastTaps = 0;
      _consecutiveSlowInteractions = 0;
      _swipeCount = 0;
    }

    _checkAndTriggerPopup();
  }

  void applyPenalty(double points, String reason) {
    if (_trustScore <= 0 || _securityQuestionAsked) return;

    _trustScore = max(_trustScore - points, 0.0);
    if (_debugMode) print('⚠️ Penalty: -${points}pts for $reason (Score: $_trustScore)');

    if (_trustScore <= 0) {
      if (_debugMode) print('🔴 Trust score depleted - Critical action required');
      _triggerLogout();
    }
  }

  // SECURITY ACTION TRIGGERS ========================================

  void _triggerOtpRequest(String reason) {
    if (!_otpRequested) {
      _otpRequested = true;
      _otpVerifiedInCurrentSession = false;
      if (_onOtpRequired != null) {
        _onOtpRequired!();
      }
      if (_showSecurityPopup != null) {
        _showSecurityPopup!(reason, 'REQUEST_OTP');
      }
      if (_debugMode) print('📲 OTP REQUESTED: $reason');
    }
  }

  void _triggerSecurityQuestion(String reason) {
    if (!_securityQuestionAsked) {
      _securityQuestionAsked = true;
      if (_onSecurityQuestionRequired != null) {
        _onSecurityQuestionRequired!();
      }
      if (_showSecurityPopup != null) {
        _showSecurityPopup!(reason, 'ASK_SECURITY_QUESTION');
      }
      if (_debugMode) print('❓ SECURITY QUESTION REQUESTED: $reason');
    }
  }

  void _checkAndTriggerPopup() {
    final action = recommendedAction;
    if (action != 'ALLOW' && _showSecurityPopup != null) {
      final message = _getActionMessage(action);
      if (_debugMode) print('🔄 Triggering popup for action: $action - $message');
      _showSecurityPopup!(message, action);
    }
  }

  String _getActionMessage(String action) {
    switch (action) {
      case 'LOG_OUT':
        return 'Suspicious activity detected. For your security, you will be logged out.';
      case 'REQUEST_OTP':
        return 'Additional verification required. Please enter the OTP sent to your registered mobile.';
      case 'ASK_SECURITY_QUESTION':
        return 'Please answer your security question to continue.';
      default:
        return 'Additional verification required.';
    }
  }

  void _triggerLogout() {
    if (_logoutCallback != null) {
      if (_debugMode) print('🔴 Executing logout callback');
      _logoutCallback!();
    }
  }

  void onOtpVerified() {
    _otpRequested = false;
    _otpVerifiedInCurrentSession = true;
    _trustScore = min(_trustScore + 30.0, 100.0);
    if (_debugMode) print('✅ OTP verified - Score increased to $_trustScore');
  }

  void onSecurityQuestionAnswered(bool correct) {
    _securityQuestionAsked = false;
    if (correct) {
      _trustScore = min(_trustScore + 40.0, 100.0);
      if (_debugMode) print('✅ Correct security answer - Score increased to $_trustScore');
    } else {
      applyPenalty(20.0, 'Incorrect security answer');
    }
  }

  // TRUST SCORE PREDICTION ==========================================

  Future<double> predictTrustScore(List<double> features) async {
    _evaluateUserBehavior();

    if (_trustScore > _modelActivationThreshold) {
      if (_debugMode) print("Using behavior-only evaluation");
      return _trustScore;
    }

    if (_debugMode) print("Activating ML model for critical evaluation");
    await _ensureModelLoaded();
    if (!_isModelLoaded) return _trustScore;

    try {
      final output = List.filled(1, 0.0).reshape([1, 1]);
      _interpreter!.run([features], output);
      double modelScore = (output[0][0] * 100).clamp(0.0, 100.0);
      _trustScore = (modelScore * 0.6) + (_trustScore * 0.4);

      if (_debugMode) {
        print('Model evaluation: $modelScore | Combined score: $_trustScore');
      }
      _checkAndTriggerPopup();

      return _trustScore;
    } catch (e) {
      if (_debugMode) print('Model evaluation failed: $e');
      return _trustScore;
    }
  }

  // PUBLIC INTERFACE ================================================

  double get currentScore => _trustScore;

  void resetScore() {
    _trustScore = 100.0;
    _lastInteraction = DateTime.now();
    _recentInteractions.clear();
    _tapTimestamps.clear();
    _consecutiveFastTaps = 0;
    _consecutiveSlowInteractions = 0;
    _swipeCount = 0;
    _tapCountInCurrentSecond = 0;
    _transactionAmount = null;
    _securityQuestionAsked = false;
    _otpRequested = false;
    _otpVerifiedInCurrentSession = false;
    _isInTransactionFlow = false;
    if (_debugMode) print('🔄 Score reset to 100');
  }

  String get recommendedAction {
    if (_trustScore <= _logoutThreshold) {
      if (_debugMode) print('🔴 LOGOUT TRIGGERED');
      return 'LOG_OUT';
    }

    // For transactions above threshold, require OTP if not already verified
    if (_isInTransactionFlow &&
        _transactionAmount != null &&
        _transactionAmount! >= _transactionOtpThreshold &&
        !_otpVerifiedInCurrentSession) {
      return 'REQUEST_OTP';
    }

    if ((_trustScore <= _otpThreshold && !_otpRequested) ||
        _consecutiveFastTaps >= 3 ||
        _tapCountInCurrentSecond >= _maxTapsPerSecond) {
      return 'REQUEST_OTP';
    }

    if ((_trustScore <= _securityQuestionThreshold && !_securityQuestionAsked) ||
        (_transactionAmount != null && _transactionAmount! >= _highValueAmount) ||
        _consecutiveSlowInteractions >= 2) {
      return 'ASK_SECURITY_QUESTION';
    }

    return 'ALLOW';
  }

  // DEMO HELPER METHODS =============================================

  void simulateFastTaps(int count) {
    if (_debugMode) print('⚡ Simulating $count fast taps...');
    for (int i = 0; i < count; i++) {
      onTap();
      if (i < count - 1) {
        _lastInteraction = _lastInteraction!.subtract(Duration(milliseconds: 300));
      }
    }
  }

  void simulateSlowInteractions(int count, int delaySeconds) {
    if (_debugMode) print('🐢 Simulating $count slow interactions ($delaySeconds seconds apart)...');
    for (int i = 0; i < count; i++) {
      if (i % 2 == 0) onTap(); else onSwipe();
      if (i < count - 1) {
        _lastInteraction = _lastInteraction!.subtract(Duration(seconds: delaySeconds));
      }
    }
  }

  void simulateSwipes(int count) {
    if (_debugMode) print('➡️ Simulating $count swipes...');
    for (int i = 0; i < count; i++) {
      onSwipe();
      if (i < count - 1) {
        _lastInteraction = _lastInteraction!.subtract(Duration(milliseconds: 500));
      }
    }
  }

  void simulateQuickPayment(double amount) {
    if (_debugMode) print('💸 Simulating quick payment of ₹$amount...');
    startTransactionFlow();
    setTransactionAmount(amount, isQuickPayment: true);
  }

  void simulateInactivity(int seconds) {
    if (_debugMode) print('⏳ Simulating $seconds seconds of inactivity...');
    _lastInteraction = _lastInteraction!.subtract(Duration(seconds: seconds));
    _evaluateUserBehavior();
  }

  void startMonitoring() {
    _monitoringTimer = Timer.periodic(Duration(seconds: 1), (_) {
      _evaluateUserBehavior();
    });
  }
}