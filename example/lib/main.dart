import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeline_editor/timeline_editor.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  Duration totalDuration = Duration(seconds: 600);

  Duration box1Start = Duration(seconds: 30);
  Duration box1Duration = Duration(seconds: 50);
  bool box1Selected = false;
  Duration box2Start = Duration(seconds: 100);
  Duration box2Duration = Duration(seconds: 180);
  bool box2Selected = false;

  Duration box1bStart = Duration(seconds: 30);
  Duration box1bDuration = Duration(seconds: 50);
  bool box1bSelected = false;
  Duration box2bStart = Duration(seconds: 100);
  Duration box2bDuration = Duration(seconds: 180);
  bool box2bSelected = false;

  bool deleted = false;
  double position = 0;
  bool customTimeString = false;
  bool withHeaders = false;
  StreamController<double> positionController;
  Timer progressTimer;
  TimelineEditorScaleController scaleController;

  double scale;

  double _trackHeight = 100;

  AnimationController _controller;
  Animation<double> _animation;

  void moveBox1(Duration newStart) {
    if (box1Start + newStart < Duration.zero) {
      newStart = Duration.zero;
    }
    if (box1Start + newStart + box1Duration < box2Start)
      setState(() {
        box1Start += newStart;
      });
  }

  void moveBox1End(Duration move) {
    if (box1Start + box1Duration + move < box2Start)
      setState(() => box1Duration = box1Duration + move);
  }

  void moveBox2(Duration startMove) {
    var newStart = box2Start + startMove;
    if (box1Start + box1Duration < newStart &&
        newStart + box2Duration < totalDuration)
      setState(() {
        box2Start = newStart;
      });
  }

  void moveBox2End(Duration move) {
    if (box2Start + box2Duration + move < totalDuration)
      setState(() => box2Duration = box2Duration + move);
  }

  // 2nd track

  void moveBox1b(Duration newStart) {
    if (box1bStart + newStart < Duration.zero) {
      newStart = Duration.zero;
    }
    if (box1bStart + newStart + box1bDuration < box2bStart)
      setState(() {
        box1bStart += newStart;
      });
  }

  void moveBox1bEnd(Duration move) {
    if (box1bStart + box1bDuration + move < box2bStart)
      setState(() => box1bDuration = box1bDuration + move);
  }

  void moveBox2b(Duration startMove) {
    var newStart = box2bStart + startMove;
    if (box1Start + box1bDuration < newStart &&
        newStart + box2bDuration < totalDuration)
      setState(() {
        box2bStart = newStart;
      });
  }

  void moveBox2bEnd(Duration move) {
    if (box2bStart + box2bDuration + move < totalDuration)
      setState(() => box2bDuration = box2bDuration + move);
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
    scaleController = TimelineEditorScaleController();
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
    scaleController.dispose();
    progressTimer?.cancel();
    positionController?.close();

    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Timeline_editor example app'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
                child: Center(
                    child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Timeline_editor example app'),
                StreamBuilder<double>(
                    stream: scaleController.scaleUpdates,
                    initialData: 1,
                    builder: (context, snapshot) {
                      return Text('Current scale: ' + snapshot.data.toString());
                    }),
                RaisedButton(
                  child: const Text('Change track height'),
                  onPressed: () =>
                      _controller.status == AnimationStatus.forward ||
                              _controller.status == AnimationStatus.completed
                          ? _controller.reverse()
                          : _controller.forward(),
                ),
                SwitchListTile(
                    title: Text('Custom time string'),
                    value: customTimeString,
                    onChanged: (value) =>
                        setState(() => customTimeString = value)),
                SwitchListTile(
                    title: Text('Headers'),
                    value: withHeaders,
                    onChanged: (value) => setState(() => withHeaders = value)),
              ],
            ))),
            Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TimelineEditor(
                  timeHeight: 20,
                  scaleController: scaleController,
                  minimumTimeWidgetExtent: customTimeString ? 100 : null,
                  leadingWidgetBuilder: withHeaders
                      ? (index) => Center(
                          child: RaisedButton(
                              onPressed: () {}, child: Text("$index")))
                      : null,
                  timelineLeadingWidget:
                      withHeaders ? Center(child: Text("HEADER")) : null,
                  timeWidgetBuilder: customTimeString
                      ? (d, t) => Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              '${d.inSeconds}/${t.inSeconds}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                      : null,
                  onPositionTap: (s) => position = s,
                  positionStream: positionController.stream,
                  countTracks: 1,
                  trackBuilder: (track, pps, duration, scrollControllers) =>
                       TimelineEditorTrack(
                              // key: Key('separated'),
                              scrollControllers: scrollControllers,
                              defaultColor: Colors.green[700],
                              boxes: [
                                TimelineEditorCard(
                                  box1Start,
                                  duration: box1Duration,
                                  selected: box1Selected,
                                  onTap: () => setState(
                                      () => box1Selected = !box1Selected),
                                  color: Colors.blue,
                                  onMovedDuration: moveBox1End,
                                  onMovedStart: moveBox1,
                                ),

                              ],
                              pixelsPerSeconds: pps,
                              duration: duration,
                            )
                          ,
                  duration: totalDuration,
                )),
          ],
        ),
      ),
    );
  }
}
