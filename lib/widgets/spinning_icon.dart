import 'dart:async';

import 'package:flutter/material.dart';

class SpinningIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const SpinningIcon({required this.icon, required this.color, Key? key}) : super(key: key);

  @override
  _SpinningIconState createState() => _SpinningIconState();
}

class _SpinningIconState extends State<SpinningIcon> {
  double _angle = 0.0; // Variable to hold the rotation angle

  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Start a timer to update the angle every 100 milliseconds
    timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        _angle += 0.15; // Increment the angle
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _angle, // Use the angle for rotation
      child: Icon(widget.icon, color: widget.color),
    );
  }
}