import 'dart:math';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class AnimatedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomAnimationBuilder<double>(
      control: Control.loop,
      tween: Tween(begin: 0.0, end: 2 * pi),
      duration: Duration(seconds: 25),
      builder: (context, value, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(value),
              colors: [
                Color(0x998BB1FF), // Bleu clair semi-transparent
                //Colors.blue.shade200,
                Color(0xFFFFFFFF),

                Color(0x998BB1FF),
              ],
            ),
          ),
        );
      },
    );
  }
}
