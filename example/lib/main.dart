import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:timeline_editor/timeline_editor.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
  }

  static const List<TimelineEditorBox> boxes = [
    TimelineEditorBox(0, 10),
    TimelineEditorBox(15, 10),
  ];

  static const List<TimelineEditorContinuousBox> boxesContinuous = [
    TimelineEditorContinuousBox(0),
    TimelineEditorContinuousBox(15),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TimelineEditor(
              countTracks: 2,
              trackBuilder: (track, pps, duration) => track == 1
                  ? TimelineEditorTrack(
                      boxes: boxes,
                      pixelsPerSeconds: pps,
                      durationInSeconds: duration,
                    )
                  : TimelineEditorTrack.fromContinuous(
                      continuousBoxes: boxesContinuous,
                      pixelsPerSeconds: pps,
                      durationInSeconds: duration,
                    ),
              blocksEvery: 5,
              durationInSeconds: 300,
              child:
                  Expanded(child: Center(child: Text('Plugin example app')))),
        ),
      ),
    );
  }
}
