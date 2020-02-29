import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:timeline_editor/timeline_editor_track.dart';
export './timeline_editor_track.dart';

typedef TimelineEditorTrackBuilder = TimelineEditorTrack Function(
    int trackNumber, int pixelsPerSeconds, int duration);

class TimelineEditor extends StatefulWidget {
  final int countTracks;
  final int durationInSeconds;
  final int blocksEvery;
  final TimelineEditorTrackBuilder trackBuilder;
  final int position;

  const TimelineEditor({
    Key key,
    @required this.durationInSeconds,
    @required this.trackBuilder,
    @required this.countTracks,
    this.position,
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
    return GestureDetector(
      child: Container(
        child: Column(
          children: <Widget>[
            LayoutBuilder(
              builder: (ctx, constraints) {
                var pixelPerSeconds = max(
                    ((constraints.maxWidth ?? 600) / widget.durationInSeconds)
                        .floor(),
                    8);
                var finalBlocksEvery =
                    max(widget.blocksEvery, (50 / pixelPerSeconds).ceil());
                var totalSlots =
                    (widget.durationInSeconds / finalBlocksEvery).ceil();
                print(constraints);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Stack(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: List.generate(
                                totalSlots,
                                (i) => SizedBox(
                                    width: pixelPerSeconds.toDouble() *
                                        finalBlocksEvery,
                                    child: Text(secondsToString(
                                        i * finalBlocksEvery)))).toList(),
                          ),
                          ...List<Widget>.generate(
                              widget.countTracks,
                              (i) => widget.trackBuilder(
                                  i, pixelPerSeconds, widget.durationInSeconds))
                        ],
                      ),
                      if (widget.position != null)
                        Positioned(
                          left: (widget.position * pixelPerSeconds).toDouble(),
                          top: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.red,
                            width: 2,
                          ),
                        )
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
