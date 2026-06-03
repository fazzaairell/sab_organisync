import 'dart:math';

import 'package:flutter/material.dart';

class MobileAppWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const MobileAppWrapper({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12)});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = min(constraints.maxWidth, 430.0);
          return Center(
            child: Container(
              width: maxWidth,
              padding: padding,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
