import 'dart:async';

import 'package:rxdart/subjects.dart';

class TimelineEditorScaleController {
  final BehaviorSubject<double> _scaleStreamController =
      BehaviorSubject<double>.seeded(1);

  /// max zoom scale
  final double maxScale;

  /// min zoom scale. Default to 1
  final double minScale;

  /// scale controller uses to
  /// manually set scale
  /// get updates of scale
  /// set min & max scale
  /// Don't forget to call [dispose]
  TimelineEditorScaleController({this.minScale = 1, this.maxScale});

  Stream<double> get scaleUpdates => _scaleStreamController.stream;

  void setScale(double scale) {
    if ((minScale == null || scale >= minScale) &&
        (maxScale == null || scale <= maxScale))
      _scaleStreamController.add(scale);
  }

  Future<dynamic> dispose() {
    return _scaleStreamController.close();
  }
}
