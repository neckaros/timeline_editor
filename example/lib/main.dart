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
  double box1Start = 0;
  double box2Start = 4;

  void updateBox1(double seconds) {
    setState(() {
      box1Start += seconds;
    });
  }

  void updateBox2(double seconds) {
    setState(() {
      box2Start += seconds;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<TimelineEditorContinuousBox> boxesContinuous = [
      const TimelineEditorContinuousBox(0,
          child: Image(image: AssetImage('assets/image.jpg'))),
      TimelineEditorContinuousBox(box2Start,
          menuEntries: [
            PopupMenuItem<String>(child: Text('Delete'), value: 'deleted')
          ],
          onMoved: updateBox2,
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
                          boxes: [
                            TimelineEditorBox(box1Start, 3,
                                onMoved: updateBox1,
                                onMovedEnd: () => print('end moved')),
                            TimelineEditorBox(7, 4),
                          ],
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
