import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeline_editor/timeline_editor.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double box1Start = 0;
  double box2Start = 120;
  bool deleted = false;
  double position = 0;
  StreamController<double> positionController;
  Timer progressTimer;

  void updateBox1(double seconds) {
    if (box1Start + seconds < 0) {
      seconds = -box1Start;
    }
    setState(() {
      box1Start += seconds;
    });
  }

  void updateBox2(double seconds) {
    if (box2Start + seconds < 0) {
      seconds = -box2Start;
    }
    setState(() {
      box2Start += seconds;
    });
  }

  void positionUpdate(Timer timer) {
    position += 0.350;
    if (position > 300) position = 0;
    positionController.add(position);
    /* if (position + 0.1 < 300)
      Timer(Duration(milliseconds: 100), () => positionUpdate());*/
  }

  @override
  void initState() {
    super.initState();
    positionController = StreamController<double>();
    progressTimer = Timer.periodic(Duration(milliseconds: 350), positionUpdate);
    positionUpdate(null);
  }

  @override
  void dispose() {
    progressTimer?.cancel();
    positionController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<TimelineEditorContinuousBox> boxesContinuous = [
      TimelineEditorContinuousBox(
        0,
        color: Colors.deepOrange,
        child: const Image(image: const AssetImage('assets/image2.jpg')),
      ),
      TimelineEditorContinuousBox(
        box2Start,
        menuEntries: [
          PopupMenuItem<String>(child: Text('Delete'), value: 'deleted')
        ],
        onMoved: updateBox2,
        onSelectedMenuItem: (v) {
          print('Selected: $v');
          if (v == "deleted")
            setState(() {
              deleted = true;
            });
        },
        onTap: (start, duration) =>
            print('tapped for $start to ${start + duration}'),
        color: Colors.black,
        child: const Image(image: const AssetImage('assets/image.jpg')),
      ),
    ];

    return MaterialApp(
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Timeline_editor example app'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(child: Center(child: Text('Timeline_editor example app'))),
            Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TimelineEditor(
                  onPositionTap: (s) => position = s,
                  positionStream: positionController.stream,
                  countTracks: 2,
                  trackBuilder: (track, pps, duration) => track == 1
                      ? TimelineEditorTrack(
                          defaultColor: Colors.green[700],
                          boxes: [
                            TimelineEditorBox(box1Start, 100,
                                onMoved: updateBox1,
                                color: Colors.blue,
                                onMovedEnd: () => print('end moved')),
                            TimelineEditorBox(157, 80),
                          ],
                          pixelsPerSeconds: pps,
                          durationInSeconds: duration,
                        )
                      : TimelineEditorTrack.fromContinuous(
                          continuousBoxes:
                              deleted ? [boxesContinuous[0]] : boxesContinuous,
                          pixelsPerSeconds: pps,
                          durationInSeconds: duration,
                        ),
                  durationInSeconds: 300,
                )),
          ],
        ),
      ),
    );
  }
}
