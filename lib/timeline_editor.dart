import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:timeline_editor/timeline_editor_scale_controller.dart';
import 'package:timeline_editor/timeline_editor_track.dart';

import 'cahced_layout_builder.dart';
import 'extensions.dart';
export './timeline_editor_track.dart';
export './extensions.dart';
export './timeline_editor_scale_controller.dart';

/// [trackNumber] the track numer in the timeline editor
/// [pixelsPerSeconds] how much pixel takes a second
/// [duration] of the timeline
typedef TimelineEditorTrackBuilder = TimelineEditorTrack Function(
    int trackNumber,
    double pixelsPerSeconds,
    Duration duration,
    LinkedScrollControllerGroup scrollControllers);

/// Main timeline widget which contains the tracks
class TimelineEditor extends StatefulWidget {
  /// number of tracks
  final int countTracks;

  /// duration of the timeline
  final Duration duration;

  /// Timeline time text theme. By default we use Theme.of(context).textTheme.bodyText1
  final TextStyle timelineTextStyle;

  /// Opational: Convert duration to string for the timeline headers
  final Widget Function(Duration duration, Duration totalDuration)
      timeWidgetBuilder;

  /// Optional hright of the time bar displayed on top of the timeline.
  /// default to 30
  final double timeHeight;

  /// Optional minimum size of the time display in the timeline.
  /// Can be used if you have custom string that takes more/less than the default 70pixels
  /// ignored if blocksEvery is set
  final double minimumTimeWidgetExtent;

  /// Optional argument to force the spacing between each time widget
  /// by default we will optimize as best fitted by the [minimumTimeWidgetExtent] while keeping round number:
  /// one every seconds, 5 seconds, ten seconds, minutes, days, weeks, month years
  final Duration timeWidgetEvery;

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

  /// scale controller use to
  /// manually set scale
  /// get updates of scale
  /// set min & max scale
  final TimelineEditorScaleController scaleController;

  const TimelineEditor({
    Key key,
    @required this.duration,
    @required this.trackBuilder,
    @required this.countTracks,
    this.timelineTextStyle,
    this.timeWidgetBuilder,
    this.scaleController,
    this.timeWidgetEvery,
    this.timeHeight = 30,
    this.minimumTimeWidgetExtent = 70,
    this.separatorColor,
    this.positionStream,
    this.blocksEvery = const Duration(seconds: 5),
    this.onPositionTap,
  }) : super(key: key);
  @override
  _TimelineEditorState createState() => _TimelineEditorState();
}

class _TimelineEditorState extends State<TimelineEditor> {
  double scale = 1;
  double widgetWidth;
  double previousScale;
  double pps;
  double timeBlockSize;

  Duration _timeUnderFocal;
  double scaleFocal;

  double get scaledPixelPerSeconds => (pps ?? 1) * scale;

  TimelineEditorScaleController _ownScaleController;
  TimelineEditorScaleController get scaleController {
    if (widget.scaleController == null && _ownScaleController == null)
      _ownScaleController = TimelineEditorScaleController();

    return widget.scaleController ?? _ownScaleController;
  }

  ScrollController scrollController;
  ScrollController scrollController2;
  LinkedScrollControllerGroup _controllers;

  double previousMaxWidth;
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  void updateTimeBlockSize(double displayWidth) {
    if (widget.timeWidgetEvery != null) {
      timeBlockSize =
          widget.timeWidgetEvery.inSecondsAsDouble * scaledPixelPerSeconds;
    } else {
      var targetNumberOfTimeWidget =
          displayWidth / (widget.minimumTimeWidgetExtent ?? 70);
      var targetDurationOfTimeWidget = durationFromSeconds(
          displayWidth / scaledPixelPerSeconds / targetNumberOfTimeWidget);
      if (targetDurationOfTimeWidget.inSeconds < 5)
        timeBlockSize = 5 * scaledPixelPerSeconds;
      else if (targetDurationOfTimeWidget.inSeconds < 10)
        timeBlockSize = 10 * scaledPixelPerSeconds;
      else if (targetDurationOfTimeWidget.inSeconds < 30)
        timeBlockSize = 30 * scaledPixelPerSeconds;
      else if (targetDurationOfTimeWidget.inMinutes < 1)
        timeBlockSize = 60 * scaledPixelPerSeconds;
      else if (targetDurationOfTimeWidget.inMinutes < 60)
        timeBlockSize = (targetDurationOfTimeWidget.inMinutes + 1) *
            60 *
            scaledPixelPerSeconds;
    }
  }

  void computePPS(double width) {
    widgetWidth = width;
    pps = widgetWidth / durationToSeconds(widget.duration);
    updateTimeBlockSize(width);
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

  void _onScaleStart(double dx) {
    previousScale = scale;
    _timeUnderFocal =
        durationFromSeconds((dx + scrollController.offset) / pps / scale);
    // (details.focalPoint.dx + scrollController.offset) / pps / scale);
  }

  void _onScaleUpdate(double details) {
    // print("Details $details");
    var newScale = previousScale * details; //.scale;
    if (newScale < 1) newScale = 1;
    scaleController.setScale(newScale);
  }

  void _onScaleEnd(_) {
    previousScale = null;
    _timeUnderFocal = null;
  }

  @override
  void didUpdateWidget(TimelineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      computePPS(previousMaxWidth);
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup();
    scrollController = _controllers.addAndGet();
    scrollController2 = _controllers.addAndGet();
    scaleController.scaleUpdates.listen((s) {
      if (scale != s) {
        setState(() => scale = s);
        updateTimeBlockSize(widgetWidth);
        var offset = _controllers.offset;
        _controllers.resetScroll();
        _controllers.jumpTo(offset);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    _ownScaleController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        _onScaleStart(event.position.dx);
      },
      onExit: _onScaleEnd,
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) {
          if (event is PointerScrollEvent) {
            // print('x: ${event.position.dx}, y: ${event.position.dy}');
            // print('delta: ${event.delta}');
            // print('scroll delta: ${event.scrollDelta}');
        _onScaleStart(event.position.dx);

            if (event.scrollDelta.dy > 0) {
              _onScaleUpdate(0.2);
            }else{
              _onScaleUpdate(1.2);

            }
        _onScaleEnd(event.position.dx);

          }
        },
        child: GestureDetector(
          onScaleStart: (detail) => _onScaleStart(detail.focalPoint.dx),
          onScaleUpdate: (detail) => _onScaleUpdate(detail.scale),
          onScaleEnd: _onScaleEnd,
          child: CachedLayoutBuilder(
              parentParameters: [
                widget.duration.inSeconds,
                widget.trackBuilder,
                widget.countTracks,
                widget.positionStream,
                widget.blocksEvery,
                widget.onPositionTap,
                widget.separatorColor,
                widget.timelineTextStyle,
                Theme.of(context).brightness,
                scale,
              ],
              builder: (ctx, constraints) {
                if (pps == null || previousMaxWidth != constraints.maxWidth) {
                  computePPS(constraints.maxWidth);
                }

                var totalTimeSlots =
                    ((widgetWidth * scale) / timeBlockSize).ceil();
                var totalFullTimeSlots =
                    ((widgetWidth * scale) / timeBlockSize).floor();
                var lastTimeBlockSize =
                    (((widgetWidth * scale) / timeBlockSize) -
                            totalFullTimeSlots) *
                        timeBlockSize;

                return Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: widget.timeHeight,
                        child: ListView.builder(
                            key: Key('timelineeditor-times'),
                            controller: scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: totalTimeSlots,
                            itemBuilder: (context, index) {
                              return buildTextTime(
                                  index,
                                  scaledPixelPerSeconds,
                                  index <= totalFullTimeSlots - 1
                                      ? timeBlockSize
                                      : lastTimeBlockSize,
                                  context);
                            }),
                      ),
                      Container(
                        height: widget.timeHeight,
                        child: ListView.builder(
                            key: Key('timelineeditor-times2'),
                            controller: scrollController2,
                            scrollDirection: Axis.horizontal,
                            itemCount: totalTimeSlots,
                            itemBuilder: (context, index) {
                              return buildTextTime(
                                  index,
                                  scaledPixelPerSeconds,
                                  index <= totalFullTimeSlots - 1
                                      ? timeBlockSize
                                      : lastTimeBlockSize,
                                  context);
                            }),
                      ),
                      ...List.generate(
                          widget.countTracks,
                          (index) => widget.trackBuilder(
                              index,
                              scaledPixelPerSeconds,
                              widget.duration,
                              _controllers)),
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }

  Widget buildTextTime(int i, double scaledPixelsPerSeconds,
      double finalBlocksEvery, BuildContext context) {
    var pos =
        durationFromSeconds(i * finalBlocksEvery / scaledPixelsPerSeconds);
    if (widget.timeWidgetBuilder != null)
      return widget.timeWidgetBuilder(
        pos,
        widget.duration,
      );
    return SizedBox(
      width: finalBlocksEvery,
      child: Row(
        children: <Widget>[
          Container(
            color: Colors.black,
            width: 2,
          ),
          Flexible(
            fit: FlexFit.loose,
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                secondsToString(
                  pos,
                  widget.duration,
                ),
                style: widget.timelineTextStyle ??
                    Theme.of(context).textTheme.bodyText1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
