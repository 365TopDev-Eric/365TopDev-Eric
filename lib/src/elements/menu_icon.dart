import 'dart:math' as math;

import 'package:flutter/material.dart';

class MenuIcon extends StatelessWidget {
  const MenuIcon({Key key, this.color}) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 2,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: Icon(
          Icons.sort,
          color: color ?? Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
