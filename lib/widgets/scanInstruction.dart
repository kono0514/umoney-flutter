import 'package:flutter/material.dart';

class ScanInstruction extends StatefulWidget {
  @override
  _ScanInstructionState createState() => _ScanInstructionState();
}

class _ScanInstructionState extends State<ScanInstruction>
    with TickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _controller..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      overflow: Overflow.visible,
      children: [
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.5, -0.1),
            end: const Offset(0.25, -0.04),
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.fastOutSlowIn,
            ),
          ),
          child: Image(
            width: 140,
            image: AssetImage("assets/images/hand_right.png"),
          ),
        ),
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.4, 0.1),
            end: const Offset(-0.3, 0.04),
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.fastOutSlowIn,
            ),
          ),
          child: Image(
            width: 120,
            image: AssetImage("assets/images/hand_left.png"),
          ),
        ),
      ],
    );
  }
}
