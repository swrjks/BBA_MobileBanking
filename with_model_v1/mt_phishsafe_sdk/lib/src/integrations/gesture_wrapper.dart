import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';

class GestureWrapper extends StatefulWidget {
  final Widget child;
  final String screenName;

  const GestureWrapper({
    Key? key,
    required this.child,
    required this.screenName,
  }) : super(key: key);

  @override
  State<GestureWrapper> createState() => _GestureWrapperState();
}

class _GestureWrapperState extends State<GestureWrapper> {
  Offset? _startPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _startPosition = event.position;
        PhishSafeSDK.onTap(widget.screenName);
        print("👆 TAP on ${widget.screenName}");
      },
      onPointerUp: (event) {
        final endPosition = event.position;
        if (_startPosition != null) {
          final dy = (endPosition.dy - _startPosition!.dy).abs();
          final dx = (endPosition.dx - _startPosition!.dx).abs();

          // Detect swipe only if significant movement
          if (dy > 20 || dx > 20) {
            PhishSafeSDK.onSwipeStart(_startPosition!.dy);
            PhishSafeSDK.onSwipeEnd(endPosition.dy);
            print("👉 SWIPE from ${_startPosition!.dy} to ${endPosition.dy}");
          }
          // else {
          //   print("🟡 Not a swipe, just a tap.");
          // }

          _startPosition = null;
        }
      },
      child: widget.child,
    );
  }
}
