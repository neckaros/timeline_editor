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
    TimelineEditorBox(0, 3),
    TimelineEditorBox(7, 4),
  ];

  static List<TimelineEditorContinuousBox> boxesContinuous = [
    const TimelineEditorContinuousBox(0,
        child: Image(image: AssetImage('assets/image.jpg'))),
    TimelineEditorContinuousBox(4,
        menuEntries: [
          PopupMenuItem<String>(child: Text('Delete'), value: 'deleted')
        ],
        onSelectedMenuItem: (v) => print('Selected: $v'),
        onTap: (start, duration) =>
            print('tapped for $start to ${start + duration}'),
        color: Colors.black,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: const <Widget>[
            const Image(image: const AssetImage('assets/image.jpg')),
          ],
        )),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(child: Center(child: Text('Plugin example app'))),
            Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TimelineEditor(
                  position: 20,
                  countTracks: 2,
                  trackBuilder: (track, pps, duration) => track == 1
                      ? TimelineEditorTrack(
                          defaultColor: Colors.green[700],
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
                )),
          ],
        ),
      ),
    );
  }
}
