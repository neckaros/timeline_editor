import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:timeline_editor/timeline_editor.dart';
import 'package:timeline_editor/play_back_bean.dart';

void main() => runApp(RecordingsPage());

class RecordingsPage extends StatefulWidget {
  final String title;

  const RecordingsPage({Key key, this.title = "Recordings"}) : super(key: key);

  @override
  _RecordingsPageState createState() => _RecordingsPageState();
}

class _RecordingsPageState
    extends State<RecordingsPage> with SingleTickerProviderStateMixin {
  //use 'controller' variable to access controller


  Duration box1Start = Duration.zero;
  Duration box2Start = Duration(seconds: 120);
  bool deleted = false;
  double position = 0;
  bool customTimeString = false;
  StreamController<double> positionController;
  Timer progressTimer;
  TimelineEditorScaleController scaleController;

  double _trackHeight = 20;

  AnimationController _controller;
  Animation<double> _animation;

  void updateBox1(Duration duration) {
    if (box1Start + duration < Duration.zero) {
      duration = -box1Start;
    }
    setState(() {
      box1Start += duration;
    });
  }

  void updateBox2(Duration duration) {
    if (box2Start + duration < Duration.zero) {
      duration = -box2Start;
    }
    setState(() {
      box2Start += duration;
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
    positionController = StreamController<double>.broadcast();
    progressTimer = Timer.periodic(Duration(milliseconds: 350), positionUpdate);
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    _animation = Tween(begin: 100.0, end: 200.0).animate(_controller)
      ..addListener(() {
        setState(() => _trackHeight = _animation.value);
      });
    positionUpdate(null);
  }

  @override
  void dispose() {
    progressTimer?.cancel();
    positionController?.close();

    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      builder:(_, __)=> Material(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
                            color: Colors.grey,
                            child: TimelineEditor(
                              timeWidgetEvery:  Duration(seconds: 10),

                              separatorColor: Colors.white,
                              timelineTextStyle: TextStyle(fontSize: 15,color: Colors.white),
                              onPositionTap: (s) => position = s,
                              positionStream: positionController.stream,
                              countTracks: 1,
                              trackBuilder: (track, pps, duration, scrollControllers) =>  TimelineEditorTrack(
                                trackHeight: 80,
                                defaultColor: Colors.green[700],
                                boxes: [
                                  PlayBackBean(
                                    formatedStarTime: "00:00:10",
                                    formatedEndTime: "00:02:00"
                                  ),
                                  PlayBackBean(
                                      formatedStarTime: "00:03:00",
                                      formatedEndTime: "00:05:00"
                                  ),
                                  PlayBackBean(
                                      formatedStarTime: "00:07:00",
                                      formatedEndTime: "00:10:00"
                                  ),
                                  PlayBackBean(
                                      formatedStarTime: "00:12:00",
                                      formatedEndTime: "00:14:00"
                                  ),
                                  PlayBackBean(
                                      formatedStarTime: "00:15:00",
                                      formatedEndTime: "00:25:00"
                                  ),
                                ],
                                pixelsPerSeconds: pps,
                                duration: duration,
                                scrollControllers: scrollControllers,
                              )
                              ,
                              duration: Duration(seconds: 300),
                            ),

            ),
          ],
        ),
      ),
    );
  }

}
