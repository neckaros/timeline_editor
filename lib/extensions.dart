import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

Duration durationFromSeconds(double seconds) => Duration(microseconds: (seconds * 1000000).round());

double durationToSeconds(Duration duration) => duration.inMicroseconds / 1000000;

Offset localToGlobal(RenderSliver sliver, Offset point, {RenderObject? ancestor}) {
  return MatrixUtils.transformPoint(getTransformTo(sliver, ancestor), point);
}

extension DurationWithSeconds on Duration {
  double get inSecondsAsDouble => durationToSeconds(this);
}

Matrix4 getTransformTo(RenderSliver sliver, RenderObject? ancestor) {
  if (ancestor == null) {
    final AbstractNode? rootNode = sliver.owner?.rootNode;
    if (rootNode is RenderObject) ancestor = rootNode;
  }
  final List<RenderObject> renderers = <RenderObject>[];
  for (AbstractNode? renderer = sliver; renderer != ancestor; renderer = renderer.parent) {
    if (renderer is RenderObject) {
      renderers.add(renderer);
    } else {
      throw ArgumentError.value(sliver, "sliver", "Render not found on tree");
    }
  }
  if (ancestor != null) renderers.add(ancestor);
  final Matrix4 transform = Matrix4.identity();
  for (int index = renderers.length - 1; index > 0; index -= 1) {
    renderers[index].applyPaintTransform(renderers[index - 1], transform);
  }
  return transform;
}
