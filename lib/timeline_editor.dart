import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:timeline_editor/timeline_editor_scale_controller.dart';
import 'package:timeline_editor/timeline_editor_track.dart';

import 'cached_layout_builder.dart';
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
  LinkedScrollControllerGroup scrollControllers,
);

/// Main timeline widget which contains the tracks
class TimelineEditor extends StatefulWidget {
  /// number of tracks
  final int countTracks;

  /// duration of the timeline
  final Duration duration;

  /// Timeline time text theme. By default we use Theme.of(context).textTheme.bodyText1
  final TextStyle? timelineTextStyle;

  /// Opational: Convert duration to string for the timeline headers
  final Widget Function(Duration duration, Duration totalDuration)?
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
  final Duration? timeWidgetEvery;

  /// Color used by the time separator in the timeline.
  /// By default we use Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black87
  final Color? separatorColor;

  /// a Widget that can be displayed as headding for leading widgets.
  final Widget? timelineLeadingWidget;

  final Widget Function(int index)? leadingWidgetBuilder;

  /// the builder for each track
  /// tou can use a [TimelineEditorTrack] or your custom track
  final TimelineEditorTrackBuilder trackBuilder;

  /// optional position stream in the timeline for the position indicator
  /// we use stream to avoid rebuilding the whole widget for each position change
  final Stream<double>? positionStream;

  /// scale controller use to
  /// manually set scale
  /// get updates of scale
  /// set min & max scale
  final TimelineEditorScaleController? scaleController;

  const TimelineEditor({
    super.key,
    required this.duration,
    required this.trackBuilder,
    required this.countTracks,
    this.timelineTextStyle,
    this.timeWidgetBuilder,
    this.scaleController,
    this.timeWidgetEvery,
    this.timeHeight = 30,
    this.minimumTimeWidgetExtent = 70,
    this.separatorColor,
    this.positionStream,
    this.timelineLeadingWidget,
    this.leadingWidgetBuilder,
  });

  @override
  State<TimelineEditor> createState() => _TimelineEditorState();
}

class _TimelineEditorState extends State<TimelineEditor> {
  late double scale = scaleController.minScale;
  late double widgetWidth;
  double? previousScale;
  double? pps;
  late double timeBlockSize = widget.minimumTimeWidgetExtent;

  double get scaledPixelPerSeconds => (pps ?? 1) * scale;

  TimelineEditorScaleController? _ownScaleController;
  TimelineEditorScaleController get scaleController {
    if (widget.scaleController == null && _ownScaleController == null) {
      _ownScaleController = TimelineEditorScaleController();
    }

    return widget.scaleController ?? _ownScaleController!;
  }

  late ScrollController scrollController;
  late LinkedScrollControllerGroup _controllers;

  StreamSubscription<double>? _scaleSubscription;

  late double previousMaxWidth;
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  static double _calculateTimeBlockSizeFromBreakpoints({
    required double displayWidth,
    required double scaledPixelPerSeconds,
    required double minimumTimeWidth,
  }) {
    const List<Map<String, dynamic>> breakpoints = [
      {'duration': Duration(seconds: 5), 'size': 5},
      {'duration': Duration(seconds: 10), 'size': 10},
      {'duration': Duration(seconds: 30), 'size': 30},
      {'duration': Duration(minutes: 1), 'size': 60},
    ];
    var targetNumberOfTimeWidget = displayWidth / minimumTimeWidth;
    var targetDurationOfTimeWidget = durationFromSeconds(
        displayWidth / scaledPixelPerSeconds / targetNumberOfTimeWidget);

    final breakpoint = breakpoints.firstWhere(
      (element) => targetDurationOfTimeWidget < element['duration'],
      orElse: () => {'size': targetDurationOfTimeWidget.inSeconds - 60},
    );

    return breakpoint['size'] * scaledPixelPerSeconds;
  }

  void updateTimeBlockSize(double displayWidth) {
    if (widget.timeWidgetEvery != null) {
      timeBlockSize =
          widget.timeWidgetEvery!.inSecondsAsDouble * scaledPixelPerSeconds;
      return;
    }

    timeBlockSize = _calculateTimeBlockSizeFromBreakpoints(
      displayWidth: displayWidth,
      scaledPixelPerSeconds: scaledPixelPerSeconds,
      minimumTimeWidth: widget.minimumTimeWidgetExtent,
    );
  }

  void computePPS(double width) {
    widgetWidth = width;
    pps = widgetWidth / durationToSeconds(widget.duration);
    updateTimeBlockSize(width);
  }

  String secondsToString(Duration duration) {
    var curDuration = Duration(microseconds: duration.inMicroseconds);
    final weeks = curDuration.inDays > 7 ? (curDuration.inDays / 7).floor() : 0;
    curDuration = curDuration - Duration(days: weeks * 7);
    final days = curDuration.inDays;
    curDuration = curDuration - Duration(days: curDuration.inDays);
    final hours = curDuration.inHours;
    curDuration = curDuration - Duration(hours: curDuration.inHours);
    final minutes = curDuration.inMinutes;
    curDuration = curDuration - Duration(minutes: curDuration.inMinutes);
    final seconds = curDuration.inSeconds;

    if (weeks >= 1) {
      return '${weeks}w${days}d';
    } else if (days >= 1) {
      return '${days}d ${hours}h';
    } else if (hours >= 1) {
      return '${hours}h${twoDigits(minutes)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  void _onScaleStart(double dx) {
    previousScale = scale;
    // (details.focalPoint.dx + scrollController.offset) / pps / scale);
  }

  void _onScaleUpdate(double details) {
    final newScale = (previousScale ?? scale) * details; //.scale;
    scaleController.setScale(newScale >= 1 ? newScale : 1);
  }

  void _onScaleEnd(_) {
    previousScale = null;
  }

  @override
  void didUpdateWidget(TimelineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    previousMaxWidth = MediaQuery.of(context).size.width;
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

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      previousMaxWidth = MediaQuery.of(context).size.width;
      computePPS(previousMaxWidth);
      setState(() {});
    });

    _scaleSubscription = scaleController.scaleUpdates.listen((s) {
      while (!mounted) {}

      if (scale == s) {
        return;
      }

      setState(() => scale = s);
      updateTimeBlockSize(widgetWidth);

      _controllers.resetScroll();
      _controllers.jumpTo(_controllers.offset);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    _ownScaleController?.dispose();
    _scaleSubscription?.cancel();
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
            } else {
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
                  child: Row(
                    children: [
                      Column(
                        // mainAxisSize: MainAxisSize.max,
                        // mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            height: widget.timeHeight * 2,
                            child: widget.timelineLeadingWidget,
                          ),
                          ...List<Widget>.generate(
                            widget.countTracks,
                            (i) => SizedBox(
                              height: widget
                                  .trackBuilder(
                                    i,
                                    scaledPixelPerSeconds,
                                    widget.duration,
                                    _controllers,
                                  )
                                  .trackHeight,
                              child: widget.leadingWidgetBuilder != null
                                  ? widget.leadingWidgetBuilder!(i)
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Stack(
                          children: [
                            Column(
                              children: <Widget>[
                                SizedBox(
                                  height: widget.timeHeight,
                                  child: ListView.builder(
                                      key: const Key('timelineeditor-times'),
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
                                ...List.generate(
                                  widget.countTracks,
                                  (index) => widget.trackBuilder(
                                    index,
                                    scaledPixelPerSeconds,
                                    widget.duration,
                                    _controllers,
                                  ),
                                ),
                              ],
                            ),
                            StreamBuilder<double>(
                                stream: widget.positionStream,
                                builder: (context, snapshot) {
                                  return snapshot.hasData
                                      ? Positioned(
                                          left: (snapshot.data! *
                                                  scaledPixelPerSeconds) -
                                              scrollController.position.pixels,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            color: Colors.red,
                                            width: 5,
                                          ))
                                      : const SizedBox.shrink();
                                })
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }

  Widget buildTextTime(
    int i,
    double scaledPixelsPerSeconds,
    double finalBlocksEvery,
    BuildContext context,
  ) {
    var pos =
        durationFromSeconds(i * finalBlocksEvery / scaledPixelsPerSeconds);
    if (widget.timeWidgetBuilder != null) {
      return SizedBox(
        width: finalBlocksEvery,
        child: widget.timeWidgetBuilder!(
          pos,
          widget.duration,
        ),
      );
    }
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
                secondsToString(pos),
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
