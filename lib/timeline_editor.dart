import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeline_editor/timeline_editor_track.dart';
export './timeline_editor_track.dart';

typedef TimelineEditorTrackBuilder = TimelineEditorTrack Function(
    int trackNumber, int pixelsPerSeconds, int duration);

class TimelineEditor extends StatefulWidget {
  final Widget child;

  final int countTracks;
  final int durationInSeconds;
  final int blocksEvery;
  final TimelineEditorTrackBuilder trackBuilder;

  const TimelineEditor({
    Key key,
    @required this.child,
    @required this.durationInSeconds,
    @required this.trackBuilder,
    @required this.countTracks,
    this.blocksEvery = 5,
  }) : super(key: key);
  @override
  _TimelineEditorState createState() => _TimelineEditorState();
}

class _TimelineEditorState extends State<TimelineEditor> {
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String secondsToString(int seconds) {
    var minutes = (seconds / 60).floor();
    var remainingSeconds = seconds - (minutes * 60);

    return '${twoDigits(minutes)}:${twoDigits(remainingSeconds)}';
  }

  @override
  Widget build(BuildContext context) {
    var pixelPerSeconds = 14;
    var totalSlots = (widget.durationInSeconds / widget.blocksEvery).ceil();
    return GestureDetector(
      child: Container(
        child: Column(
          children: <Widget>[
            widget.child,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: List.generate(
                            totalSlots,
                            (i) => SizedBox(
                                width: pixelPerSeconds.toDouble() *
                                    widget.blocksEvery,
                                child: Text(
                                    secondsToString(i * widget.blocksEvery))))
                        .toList(),
                  ),
                  ...List<Widget>.generate(
                      widget.countTracks,
                      (i) => widget.trackBuilder(
                          i, pixelPerSeconds, widget.durationInSeconds))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
