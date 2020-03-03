import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:timeline_editor/timeline_editor_track.dart';
export './timeline_editor_track.dart';

/// [trackNumber] the track numer in the timeline editor
/// [pixelsPerSeconds] how much pixel takes a second
/// [duration] of the timeline
typedef TimelineEditorTrackBuilder = TimelineEditorTrack Function(
    int trackNumber, double pixelsPerSeconds, double duration);

/// Main timeline widget which contains the tracks
class TimelineEditor extends StatefulWidget {
  /// number of tracks
  final int countTracks;

  /// duration of the timeline in seconds
  final double durationInSeconds;

  /// optional distance in seconds between each time indicator
  final int blocksEvery;

  /// the builder for each track
  /// tou can use a [TimelineEditorTrack] or your custom track
  final TimelineEditorTrackBuilder trackBuilder;

  /// optional position in the timeline for the position indicator
  final double position;

  /// option initial number of pixels per seconds
  /// if not set the timeline will initially fit the screen
  final int pixelPerSeconds;

  const TimelineEditor({
    Key key,
    @required this.durationInSeconds,
    @required this.trackBuilder,
    @required this.countTracks,
    this.position,
    this.blocksEvery = 5,
    this.pixelPerSeconds,
  }) : super(key: key);
  @override
  _TimelineEditorState createState() => _TimelineEditorState();
}

class _TimelineEditorState extends State<TimelineEditor> {
  double scale = 1;
  double previousScale;
  double pps;

  double previousMaxWidth;
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  double computePPS(double width) {
    return widget.pixelPerSeconds ?? (width / widget.durationInSeconds);
  }

  String secondsToString(int seconds) {
    var minutes = (seconds / 60).floor();
    var remainingSeconds = (seconds - (minutes * 60)).floor();

    return '${twoDigits(minutes)}:${twoDigits(remainingSeconds)}';
  }

  void _onScaleStart(ScaleStartDetails details) {
    previousScale = scale;
    print('=$scale=');
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    print('=$previousScale + ${details.scale}=');
    var newScale = previousScale * details.scale;
    if (newScale < 1) newScale = 1;
    setState(() => scale = newScale);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: Container(
        child: Column(
          children: <Widget>[
            LayoutBuilder(
              builder: (ctx, constraints) {
                if (pps == null || previousMaxWidth != constraints.maxWidth) {
                  pps = computePPS(constraints.maxWidth);
                }
                var pixelPerSeconds = pps * scale;
                var finalBlocksEvery =
                    max(widget.blocksEvery, (50 / pixelPerSeconds).ceil());
                var totalSlots =
                    (widget.durationInSeconds / finalBlocksEvery).floor();
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Stack(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: List.generate(
                                  totalSlots,
                                  (i) => SizedBox(
                                      width: pixelPerSeconds * finalBlocksEvery,
                                      child: Text(secondsToString(
                                          i * finalBlocksEvery)))).toList(),
                            ),
                          ),
                          ...List<Widget>.generate(
                              widget.countTracks,
                              (i) => widget.trackBuilder(
                                  i, pixelPerSeconds, widget.durationInSeconds))
                        ],
                      ),
                      if (widget.position != null)
                        Positioned(
                          left: (widget.position * pixelPerSeconds),
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
