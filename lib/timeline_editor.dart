import 'dart:math';

import 'package:flutter/material.dart';
import 'package:timeline_editor/timeline_editor_track.dart';

import 'cahced_layout_builder.dart';
import 'extensions.dart';
export './timeline_editor_track.dart';
export './extensions.dart';

/// [trackNumber] the track numer in the timeline editor
/// [pixelsPerSeconds] how much pixel takes a second
/// [duration] of the timeline
typedef TimelineEditorTrackBuilder = TimelineEditorTrack Function(
    int trackNumber, double pixelsPerSeconds, Duration duration);

/// Main timeline widget which contains the tracks
class TimelineEditor extends StatefulWidget {
  /// number of tracks
  final int countTracks;

  /// duration of the timeline
  final Duration duration;

  /// Timeline time text theme. By default we use Theme.of(context).textTheme.bodyText1
  final TextStyle timelineTextStyle;

  /// Color used by the time separator in the timeline.
  /// By default we use Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black87
  final Color separatorColor;

  /// optional distance in seconds between each time indicator
  final Duration blocksEvery;

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
    @required this.duration,
    @required this.trackBuilder,
    @required this.countTracks,
    this.timelineTextStyle,
    this.separatorColor,
    this.positionStream,
    this.blocksEvery = const Duration(seconds: 5),
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
    return widget.pixelPerSeconds ??
        (width / durationToSeconds(widget.duration));
  }

  String secondsToString(Duration duration, Duration totalDuration) {
    var _duration = Duration(microseconds: duration.inMicroseconds);
    int weeks = _duration.inDays > 7 ? (_duration.inDays / 7).floor() : 0;
    _duration = _duration - Duration(days: weeks * 7);
    int days = _duration.inDays;
    _duration = _duration - Duration(days: _duration.inDays);
    int hours = _duration.inHours;
    _duration = _duration - Duration(hours: _duration.inHours);
    int minutes = _duration.inMinutes;
    _duration = _duration - Duration(minutes: _duration.inMinutes);
    int seconds = _duration.inSeconds;

    if (weeks > 1)
      return '${weeks}w${days}d';
    else if (days > 1)
      return '${days}d ${hours}h';
    else if (hours > 1)
      return '${hours}h${twoDigits(minutes)}';
    else
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
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
                widget.duration.inSeconds,
                widget.trackBuilder,
                widget.countTracks,
                widget.positionStream,
                widget.blocksEvery,
                widget.pixelPerSeconds,
                widget.onPositionTap,
                widget.separatorColor,
                widget.timelineTextStyle,
                Theme.of(context).brightness,
                scale,
              ],
              builder: (ctx, constraints) {
                if (pps == null || previousMaxWidth != constraints.maxWidth) {
                  pps = computePPS(constraints.maxWidth);
                }
                var pixelPerSeconds = pps * scale;
                var finalBlocksEvery = max(
                    durationToSeconds(widget.blocksEvery),
                    (70 / pixelPerSeconds));
                var totalSlots =
                    (durationToSeconds(widget.duration) / finalBlocksEvery)
                        .floor();
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth * scale,
                    child: Stack(
                      overflow: Overflow.clip,
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
                                              color: widget.separatorColor ??
                                                  (Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white60
                                                      : Colors.black87),
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
                                              (i) => i == totalSlots
                                                  ? Expanded(
                                                      child: buildTextTime(
                                                          i,
                                                          finalBlocksEvery,
                                                          context),
                                                    )
                                                  : SizedBox(
                                                      width: pixelPerSeconds *
                                                          finalBlocksEvery,
                                                      child: buildTextTime(
                                                          i,
                                                          finalBlocksEvery,
                                                          context),
                                                    ),
                                            ).toList(),
                                          );
                                        }),
                                  ),
                                ],
                              ),
                            ),
                            ...List<Widget>.generate(
                                widget.countTracks,
                                (i) => widget.trackBuilder(
                                    i, pixelPerSeconds, widget.duration))
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
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Padding buildTextTime(int i, double finalBlocksEvery, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        secondsToString(
          Duration(
            milliseconds: ((i * finalBlocksEvery) * 1000).toInt(),
          ),
          widget.duration,
        ),
        style:
            widget.timelineTextStyle ?? Theme.of(context).textTheme.bodyText1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
