import 'package:graphic/src/aes/color.dart';
import 'package:graphic/src/aes/elevation.dart';
import 'package:graphic/src/aes/gradient.dart';
import 'package:graphic/src/aes/label.dart';
import 'package:graphic/src/aes/position.dart';
import 'package:graphic/src/aes/shape.dart';
import 'package:graphic/src/aes/size.dart';

import 'function.dart';

class Interval extends FunctionElement {
  Interval({
    ColorAttr? color,
    ElevationAttr? elevation,
    GradientAttr? gradient,
    LabelAttr? label,
    PositionAttr? position,
    ShapeAttr? shape,
    SizeAttr? size,
  }) : super(
    color: color,
    elevation: elevation,
    gradient: gradient,
    label: label,
    position: position,
    shape: shape,
    size: size,
  );
}
