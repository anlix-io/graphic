import 'package:graphic/src/common/dim.dart';
import 'package:graphic/src/coord/coord.dart';
import 'package:graphic/src/dataflow/tuple.dart';
import 'dart:ui';
import 'dart:math';

import 'package:graphic/src/interaction/gesture.dart';

import 'selection.dart';

/// The selection to select discrete data values.
class PointSelection extends Selection {
  /// Creates a point selection.
  PointSelection({
    this.toggle,
    this.nearest,
    this.testRadius,
    this.bothDimTest=false,
    Dim? dim,
    String? variable,
    Set<GestureType>? on,
    Set<GestureType>? clear,
    Set<PointerDeviceKind>? devices,
    int? layer,
  }) : super(
          dim: dim,
          variable: variable,
          on: on,
          clear: clear,
          devices: devices,
          layer: layer,
        );

  /// Whether triggered tuples should be toggled (inserted or removed from) or replace
  /// existing selected tuples.
  ///
  /// If null, a default false is set.
  bool? toggle;

  /// To select the tuple nearest to the pointer in the coordinate, Even if it's
  /// out of [testRadius].
  ///
  /// If null, a default true is set.
  bool? nearest;

  /// Radius of the pointer test.
  ///
  /// If null, a default 10 is set.
  double? testRadius;

  //
  // If [bothDimTest] is true, will try to test when pointer is inside
  // both dimensions. [dim] field still would be useful aggregating tuples
  // on a selection. 
  //
  bool bothDimTest = false;

  @override
  bool operator ==(Object other) =>
      other is PointSelection &&
      super == other &&
      toggle == other.toggle &&
      nearest == other.nearest &&
      testRadius == other.testRadius;
}

/// The point selector.
///
/// The [points] have only one point.
class PointSelector extends Selector {
  PointSelector(
    this.toggle,
    this.nearest,
    this.testRadius,
    this.bothDimTest,
    Dim? dim,
    String? variable,
    List<Offset> points,
  )   : assert(toggle != true || variable == null),
        super(
          dim,
          variable,
          points,
        );

  final bool toggle;

  final bool nearest;

  final double testRadius;
  
  final bool bothDimTest;

  @override
  Set<int>? select(
    AesGroups groups,
    List<Tuple> tuples,
    Set<int>? preSelects,
    CoordConv coord,
  ) {
    int nearestIndex = -1;
    // nearestDistance is a canvas distance.
    double nearestDistance = double.infinity;
    void Function(Aes) updateNearest;

    final point = coord.invert(points.single);
    if (dim == null) {
      updateNearest = (aes) {
        final offset = aes.representPoint - point;
        // The neighborhood is an approximate square.
        final distance = (offset.dx.abs() + offset.dy.abs()) / 2;
        if (distance < nearestDistance) {
          nearestIndex = aes.index;
          nearestDistance = distance;
        }
      };
    } else if ( bothDimTest ){
      // bothDimTest only works with 2-point aes for now
      // it checks if point is between both aes's points
      // with a minor error margin (epsilon)
      updateNearest = (aes) {
        if( aes.position.length == 2 ){
          Offset p1 = aes.position[0];
          Offset p2 = aes.position[1];
          // ignore: invalid_use_of_protected_member
          double epsilon = ( aes.size ?? aes.shape.defaultSize ) / coord.region.width ;
          epsilon /= 2;
          if( min( p1.dx , p2.dx)-epsilon < point.dx && max( p1.dx , p2.dx)+epsilon > point.dx ){
            if( min( p1.dy , p2.dy) < point.dy && max( p1.dy , p2.dy) > point.dy ){
              nearestIndex = aes.index;
              nearestDistance = 0;
            }
          }
        }
      };
    } else {
      final getProjection = dim == Dim.x
          ? (Offset offset) => offset.dx
          : (Offset offset) => offset.dy;
      updateNearest = (aes) {
        final p = aes.representPoint;
        final distance = (getProjection(point) - getProjection(p)).abs();
        if (distance < nearestDistance) {
          nearestIndex = aes.index;
          nearestDistance = distance;
        }
      };
    }

    for (var group in groups) {
      for (var aes in group) {
        updateNearest(aes);
      }
    }

    if (!nearest) {
      if (nearestDistance > coord.invertDistance(testRadius)) {
        return null;
      }
    }

    if (variable != null) {
      // Not toggle.

      final rst = <int>{};
      final value = tuples[nearestIndex][variable];
      for (var i = 0; i < tuples.length; i++) {
        if (tuples[i][variable] == value) {
          rst.add(i);
        }
      }
      return rst.isEmpty ? null : rst;
    }

    Set<int> rst;
    if (toggle && preSelects != null) {
      if (preSelects.contains(nearestIndex)) {
        rst = {...preSelects}..remove(nearestIndex);
      } else {
        rst = {...preSelects}..add(nearestIndex);
      }
    } else {
      rst = {nearestIndex};
    }
    return rst.isEmpty ? null : rst;
  }
}
