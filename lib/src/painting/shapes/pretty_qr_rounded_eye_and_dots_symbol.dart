// import 'package:meta/meta.dart';
// import 'package:flutter/painting.dart';

// import 'package:pretty_qr_code/src/painting/pretty_qr_brush.dart';
// import 'package:pretty_qr_code/src/painting/pretty_qr_shape.dart';
// import 'package:pretty_qr_code/src/rendering/pretty_qr_painting_context.dart';
// import 'package:pretty_qr_code/src/rendering/pretty_qr_render_capabilities.dart';
// import 'package:pretty_qr_code/src/painting/extensions/pretty_qr_module_extensions.dart';

// /// A rectangular symbol with rounded corners.
// @sealed
// class PrettyQrRoundedEyeAndDotsSymbol extends PrettyQrShape {
//   /// The color or brush to use when filling the QR code.
//   @nonVirtual
//   final Color color;

//   /// If non-null, the corners of QR modules are rounded by this [BorderRadius].
//   @nonVirtual
//   final BorderRadiusGeometry borderRadius;

//   /// The default value for [borderRadius].
//   static const kDefaultBorderRadius = BorderRadius.all(
//     Radius.circular(8),
//   );

//   /// Creates a basic QR shape.
//   @literal
//   const PrettyQrRoundedEyeAndDotsSymbol({
//     this.color = const Color(0xFF000000),
//     this.borderRadius = kDefaultBorderRadius,
//   });

//   @override
//   void paint(PrettyQrPaintingContext context) {
//     final path = Path();
//     final brush = PrettyQrBrush.from(color);

//     final paint = brush.toPaint(
//       context.estimatedBounds,
//       textDirection: context.textDirection,
//     );

//     final radius = borderRadius.resolve(context.textDirection);

//     for (final module in context.matrix) {
//       if (!module.isDark) continue;

//       final moduleRect = module.resolveRect(context);
//       final modulePath = Path()
//         ..addRRect(radius.toRRect(moduleRect))
//         ..close();

//       if (PrettyQrRenderCapabilities.needsAvoidComplexPaths) {
//         context.canvas.drawPath(modulePath, paint);
//       } else {
//         path.addPath(modulePath, Offset.zero);
//       }
//     }

//     path.close();
//     context.canvas.drawPath(path, paint);
//   }

//   @override
//   PrettyQrRoundedEyeAndDotsSymbol? lerpFrom(PrettyQrShape? a, double t) {
//     if (identical(a, this)) {
//       return this;
//     }

//     if (a == null) return this;
//     if (a is! PrettyQrRoundedEyeAndDotsSymbol) return null;

//     if (t == 0.0) return a;
//     if (t == 1.0) return this;

//     return PrettyQrRoundedEyeAndDotsSymbol(
//       color: PrettyQrBrush.lerp(a.color, color, t)!,
//       borderRadius: BorderRadiusGeometry.lerp(a.borderRadius, borderRadius, t)!,
//     );
//   }

//   @override
//   PrettyQrRoundedEyeAndDotsSymbol? lerpTo(PrettyQrShape? b, double t) {
//     if (identical(this, b)) {
//       return this;
//     }

//     if (b == null) return this;
//     if (b is! PrettyQrRoundedEyeAndDotsSymbol) return null;

//     if (t == 0.0) return this;
//     if (t == 1.0) return b;

//     return PrettyQrRoundedEyeAndDotsSymbol(
//       color: PrettyQrBrush.lerp(color, b.color, t)!,
//       borderRadius: BorderRadiusGeometry.lerp(borderRadius, b.borderRadius, t)!,
//     );
//   }

//   @override
//   int get hashCode {
//     return Object.hash(runtimeType, color, borderRadius);
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(other, this)) return true;
//     if (other.runtimeType != runtimeType) return false;

//     return other is PrettyQrRoundedEyeAndDotsSymbol &&
//         other.color == color &&
//         other.borderRadius == borderRadius;
//   }
// }

import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:pretty_qr_code/src/painting/extensions/pretty_qr_module_extensions.dart';
import 'package:pretty_qr_code/src/painting/pretty_qr_brush.dart';
import 'package:pretty_qr_code/src/painting/pretty_qr_shape.dart';
import 'package:pretty_qr_code/src/rendering/pretty_qr_painting_context.dart';

@sealed
class PrettyQrRoundedEyeAndDotsSymbol extends PrettyQrShape {
  final Color color;
  final BorderRadiusGeometry moduleRadius;
  final BorderRadiusGeometry eyeOuterRadius;
  final BorderRadiusGeometry eyeInnerRadius;

  static const _defaultModuleRadius = BorderRadius.all(Radius.circular(4));
  static const _defaultEyeOuterRadius = BorderRadius.all(Radius.circular(8));
  static const _defaultEyeInnerRadius = BorderRadius.all(Radius.circular(4));

  const PrettyQrRoundedEyeAndDotsSymbol({
    this.color = const Color(0xFF000000),
    this.moduleRadius = _defaultModuleRadius,
    this.eyeOuterRadius = _defaultEyeOuterRadius,
    this.eyeInnerRadius = _defaultEyeInnerRadius,
  });

  @override
  void paint(PrettyQrPaintingContext context) {
    final dim = context.matrix.dimension;
    final paint = PrettyQrBrush.from(color)
        .toPaint(context.estimatedBounds, textDirection: context.textDirection);

    // 1) draw all non‑eye modules as dots
    final mRadius = moduleRadius.resolve(context.textDirection);
    for (final module in context.matrix) {
      if (!module.isDark) continue;
      if (_isInFinderPattern(module.x, module.y, dim)) continue;

      final rect = module.resolveRect(context);
      context.canvas.drawRRect(
        mRadius.toRRect(rect),
        paint,
      );
    }

    // 2) draw the 3 finder‑pattern “eyes”
    _drawFinderEye(context, 0, 0, paint); // top‑left
    _drawFinderEye(context, dim - 7, 0, paint); // top‑right
    _drawFinderEye(context, 0, dim - 7, paint); // bottom‑left
  }

  bool _isInFinderPattern(int x, int y, int dim) {
    // each finder pattern is a 7×7 block
    return (x < 7 && y < 7) ||
        (x >= dim - 7 && y < 7) ||
        (x < 7 && y >= dim - 7);
  }

  void _drawFinderEye(
    PrettyQrPaintingContext context,
    int startX,
    int startY,
    Paint paint,
  ) {
    final cellSize = context.boundsDimension / context.matrix.dimension;
    final outerSize = cellSize * 7;
    // final innerOffset = cellSize * 2;
    final innerSize = cellSize * 3;

    // outer square
    final outerRect = Rect.fromLTWH(
      startX * cellSize,
      startY * cellSize,
      outerSize,
      outerSize,
    );
    context.canvas.drawRRect(
      eyeOuterRadius.resolve(context.textDirection).toRRect(outerRect),
      paint,
    );

    // “white” gap: cover a 5×5 area inside with a clear brush
    // final clearPaint = Paint()..blendMode = BlendMode.clear;
    // final clearPaint = Paint()..color = const Color(0x00FFFFFF);
    final clearPaint = Paint()..invertColors = true;
    final gapRect = Rect.fromLTWH(
      (startX + 1) * cellSize,
      (startY + 1) * cellSize,
      cellSize * 5,
      cellSize * 5,
    );
    context.canvas.drawRRect(
      eyeInnerRadius.resolve(context.textDirection).toRRect(gapRect),
      clearPaint,
    );

    // inner square
    final innerRect = Rect.fromLTWH(
      (startX + 2) * cellSize,
      (startY + 2) * cellSize,
      innerSize,
      innerSize,
    );
    context.canvas.drawRRect(
      eyeInnerRadius.resolve(context.textDirection).toRRect(innerRect),
      paint,
    );
  }

  @override
  PrettyQrRoundedEyeAndDotsSymbol? lerpFrom(PrettyQrShape? a, double t) => this;
  @override
  PrettyQrRoundedEyeAndDotsSymbol? lerpTo(PrettyQrShape? b, double t) => this;

  @override
  int get hashCode =>
      Object.hash(color, moduleRadius, eyeOuterRadius, eyeInnerRadius);
  @override
  bool operator ==(Object other) =>
      other is PrettyQrRoundedEyeAndDotsSymbol &&
      other.color == color &&
      other.moduleRadius == moduleRadius &&
      other.eyeOuterRadius == eyeOuterRadius &&
      other.eyeInnerRadius == eyeInnerRadius;
}
