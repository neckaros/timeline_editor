import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Duration durationFromSeconds(double seconds) =>
    Duration(microseconds: (seconds * 1000000).round());

double durationToSeconds(Duration duration) =>
    duration.inMicroseconds / 1000000;

Offset localToGlobal(RenderSliver sliver, Offset point,
    {RenderObject? ancestor}) {
  return MatrixUtils.transformPoint(getTransformTo(sliver, ancestor), point);
}

extension DurationWithSeconds on Duration {
  double get inSecondsAsDouble => durationToSeconds(this);
}

Matrix4 getTransformTo(RenderSliver sliver, RenderObject? ancestor) {
  final bool ancestorSpecified = ancestor != null;
  if (ancestor == null) {
    final AbstractNode? rootNode = sliver.owner!.rootNode;
    if (rootNode is RenderObject) ancestor = rootNode;
  }
  final List<RenderObject?> renderers = <RenderObject?>[];
  for (RenderSliver? renderer = sliver;
      renderer != ancestor;
      renderer = renderer!.parent as RenderSliver?) {
    assert(renderer != null); // Failed to find ancestor in parent chain.
    renderers.add(renderer);
  }
  if (ancestorSpecified) renderers.add(ancestor);
  final Matrix4 transform = Matrix4.identity();
  for (int index = renderers.length - 1; index > 0; index -= 1) {
    renderers[index]!.applyPaintTransform(renderers[index - 1]!, transform);
  }
  return transform;
}
