import 'dart:math';

import 'package:flutter/material.dart';
import 'package:timeline_editor/timeline_editor_track.dart';

import 'cahced_layout_builder.dart';
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

  /// optional position stream in the timeline for the position indicator
  /// we use stream to avoid rebuilding the whole widget for each position change
  final Stream<double> positionStream;

  /// user whant to switch to a time position in seconds
  final void Function(double position) onPositionTap;

  /// option initial number of pixels per seconds
  /// if not set the timeline will initially fit the screen
  final int pixelPerSeconds;

  const TimelineEditor({
    Key key,
    @required this.durationInSeconds,
    @required this.trackBuilder,
    @required this.countTracks,
    this.positionStream,
    this.blocksEvery = 5,
    this.pixelPerSeconds,
    this.onPositionTap,
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

  String secondsToString(double seconds) {
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

  void _positionTap(TapUpDetails details) {
    var pixelPerSeconds = pps * scale;
    var secondsClick = details.localPosition.dx / pixelPerSeconds;
    widget.onPositionTap?.call(secondsClick);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: Container(
        child: Column(
          children: <Widget>[
            CachedLayoutBuilder(
              parentParameters: [
                widget.durationInSeconds,
                widget.trackBuilder,
                widget.countTracks,
                widget.positionStream,
                widget.blocksEvery,
                widget.pixelPerSeconds,
                widget.onPositionTap,
                scale,
              ],
              builder: (ctx, constraints) {
                if (pps == null || previousMaxWidth != constraints.maxWidth) {
                  pps = computePPS(constraints.maxWidth);
                }
                var pixelPerSeconds = pps * scale;
                var finalBlocksEvery =
                    max(widget.blocksEvery, (70 / pixelPerSeconds));
                var totalSlots =
                    (widget.durationInSeconds / finalBlocksEvery).floor();
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Stack(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          GestureDetector(
                            onTapUp: _positionTap,
                            child: Stack(
                              children: <Widget>[
                                ...List.generate(
                                    totalSlots + 1,
                                    (i) => Positioned(
                                          left: i *
                                              pixelPerSeconds *
                                              finalBlocksEvery,
                                          top: 8,
                                          bottom: 8,
                                          child: Container(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white60
                                                    : Colors.black87,
                                            width: 1,
                                          ),
                                        )),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 8.0, top: 8.0),
                                  child: StreamBuilder<Object>(
                                      stream: null,
                                      builder: (context, snapshot) {
                                        return Row(
                                          children: List.generate(
                                              totalSlots + 1,
                                              (i) => SizedBox(
                                                  width: pixelPerSeconds *
                                                      finalBlocksEvery,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 8.0),
                                                    child: Text(secondsToString(
                                                        i * finalBlocksEvery)),
                                                  ))).toList(),
                                        );
                                      }),
                                ),
                              ],
                            ),
                          ),
                          ...List<Widget>.generate(
                              widget.countTracks,
                              (i) => widget.trackBuilder(
                                  i, pixelPerSeconds, widget.durationInSeconds))
                        ],
                      ),
                      if (widget.positionStream != null)
                        StreamBuilder<double>(
                            stream: widget.positionStream,
                            builder: (context, snapshot) {
                              double position =
                                  snapshot.data == null ? 0 : snapshot.data;
                              return AnimatedPositioned(
                                duration: Duration(milliseconds: 350),
                                left: (position * pixelPerSeconds),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              );
                            })
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
