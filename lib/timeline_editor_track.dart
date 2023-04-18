import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

import 'package:timeline_editor/extensions.dart';

/// a box to be displayed in a [TimelineEditorTrack] with a [start] and a [duration]
class TimelineEditorCard extends ITimelineEditorCard {
  /// is the box selected
  final bool selected;

  /// When the user tap the box. Can be used to toggle selected status
  final VoidCallback? onTap;

  /// this box is a separated and not a card
  final bool? isSeparator;

  /// optional  custom child to display in this box
  final Widget? child;

  /// background color of this box
  final Color? color;

  /// optional border color when selected
  final Color? borderColor;

  /// optional [PopupMenuEntry] list to display if a user long press this box
  final List<PopupMenuEntry> menuEntries;

  /// optional callback when a user click on one of the [menuEntries]
  final void Function(Object selectedItem)? onSelectedMenuItem;

  /// optional callback that will activate the
  /// possibility of moving this box
  final void Function(Duration duration)? onMovedDuration;

  /// optional callback that will activate the
  /// possibility of moving this box
  final void Function(Duration duration)? onMovedStart;

  /// optional icon for [onMovedStart]
  final Icon? onMovedStartIcon;

  /// optional icon for [onMovedDuration]
  final Icon? onMovedDurationIcon;

  /// optional icon for [menuEntries]
  final Icon? menuEntriesIcon;

  const TimelineEditorCard(
    Duration start, {
    super.key,
    required super.duration,
    this.isSeparator,
    this.selected = false,
    required this.onTap,
    this.child,
    this.color,
    this.borderColor,
    this.menuEntries = const [],
    this.onSelectedMenuItem,
    this.onMovedDuration,
    this.onMovedStart,
    this.onMovedStartIcon,
    this.onMovedDurationIcon,
    this.menuEntriesIcon,
  }) : super(start: start);

  @override
  Widget build(
    BuildContext context, {
    required double pixelsPerSeconds,
    required Duration availableSpace,
  }) {
    return TimelineEditorSizedBox(
      duration: duration ?? (start - availableSpace),
      pixelsPerSeconds: pixelsPerSeconds,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          margin: EdgeInsets.all(1.0),
          color: color,
          elevation: 2,
          child: Stack(children: [
            child != null ? Positioned.fill(child: child!) : SizedBox.shrink(),
            if (selected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor ?? Colors.white,
                      width: 6,
                    ),
                  ),
                ),
              ),
            if (onMovedDuration != null && selected)
              GestureDetector(
                onHorizontalDragUpdate: (d) => onMovedDuration
                    ?.call(durationFromSeconds(d.delta.dx / pixelsPerSeconds)),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: Container(
                      color: borderColor ?? Colors.white,
                      child: onMovedDurationIcon != null
                          ? onMovedDurationIcon
                          : Icon(
                              Icons.swap_horiz,
                              color: Colors.black,
                            ),
                    ),
                  ),
                ),
              ),
            if (onMovedStart != null && selected)
              GestureDetector(
                onHorizontalDragUpdate: (d) => onMovedStart
                    ?.call(durationFromSeconds(d.delta.dx / pixelsPerSeconds)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: Container(
                      color: borderColor ?? Colors.white,
                      child: onMovedStartIcon != null
                          ? onMovedStartIcon
                          : Icon(
                              Icons.swap_horiz,
                              color: Colors.black,
                            ),
                    ),
                  ),
                ),
              ),
            if (menuEntries.isNotEmpty && selected)
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: PopupMenuButton(
                    onSelected: (v) => onSelectedMenuItem?.call(v),
                    itemBuilder: (BuildContext context) {
                      return menuEntries;
                    },
                    child: Container(
                      color: borderColor != null ? borderColor : Colors.white,
                      child: menuEntriesIcon != null
                          ? menuEntriesIcon
                          : Icon(
                              Icons.menu,
                              color: Colors.black,
                            ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class TimelineEditorEmptyCardTapResult {
  final Duration start;
  final Duration end;
  final Duration duration;
  final Duration tap;

  const TimelineEditorEmptyCardTapResult({
    required this.start,
    required this.duration,
    required this.tap,
  }) : end = start + duration;

  @override
  String toString() =>
      'TimelineEditorEmptyCardTapResult(start: $start, end: $end, tap: $tap)';
}

class TimelineEditorEmptyCard extends ITimelineEditorCard {
  final ValueChanged<TimelineEditorEmptyCardTapResult>? onTap;
  const TimelineEditorEmptyCard({
    super.key,
    required super.start,
    required Duration duration,
    required this.onTap,
  }) : super(duration: duration);

  Widget build(
    BuildContext context, {
    required double pixelsPerSeconds,
    required Duration availableSpace,
  }) {
    final card = TimelineEditorSizedBox(
      duration: duration,
      pixelsPerSeconds: pixelsPerSeconds,
      child: Container(),
    );

    if (onTap == null) {
      return card;
    }

    return GestureDetector(
      onTapUp: (details) {
        final tap = start +
            durationFromSeconds(
              details.localPosition.dx / pixelsPerSeconds,
            );
        onTap!.call(TimelineEditorEmptyCardTapResult(
          start: start,
          duration: duration!,
          tap: tap,
        ));
      },
      child: Container(
        color: Colors.transparent,
        child: card,
      ),
    );
  }
}

abstract class ITimelineEditorCard {
  final Key? key;

  /// duration in seconds of the box. Let it null for continuous boxes
  final Duration? duration;

  /// the start time in seconds of this box
  final Duration start;

  const ITimelineEditorCard({
    this.key,
    required this.start,
    this.duration,
  });

  Widget build(
    BuildContext context, {
    required double pixelsPerSeconds,
    required Duration availableSpace,
  });
}

class TimelineEditorSizedBox extends StatelessWidget {
  final Duration? duration;
  final double pixelsPerSeconds;
  final double? height;
  final Widget child;

  const TimelineEditorSizedBox({
    super.key,
    this.height,
    this.duration,
    required this.pixelsPerSeconds,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = duration != null
        ? durationToSeconds(duration!) * pixelsPerSeconds
        : 0.0;
    return SizedBox(
      width: width > 0 ? width : 0,
      height: height ?? 100,
      child: child,
    );
  }
}

/// A widget that displays a horizontal timeline track for a given duration, with customizable cards displayed
/// along the timeline. Each card can represent a block of time and can be interacted with by the user.
///
/// The [boxes] list contains the cards to be displayed on the track. Each card must implement the [ITimelineEditorCard]
/// interface.
///
/// The [pixelsPerSeconds] parameter determines how many pixels represent one second on the timeline. This value
/// affects the scale of the timeline and how quickly the user can scrub through it.
///
/// The [scrollControllers] parameter is a [LinkedScrollControllerGroup] that links the scrolling behavior of this
/// track with other tracks in the timeline editor. This allows the user to horizontally scroll through multiple
/// tracks at once.
///
/// The [onEmptySlotTap] parameter is a callback that is called when the user taps an empty space on the timeline.
/// It provides a [TimelineEditorEmptyCardTapResult] object that contains information about the tapped location
/// on the timeline, such as the start time and duration of the selected area.
///
/// The [trackHeight] parameter determines the height of the track.
///
/// The [duration] parameter specifies the total duration of the timeline.
///
/// The [defaultColor] parameter specifies the default color to use for cards that do not provide their own color.
class TimelineEditorTrack extends StatefulWidget {
  final List<ITimelineEditorCard> boxes;
  final double pixelsPerSeconds;
  final LinkedScrollControllerGroup scrollControllers;
  final ValueChanged<TimelineEditorEmptyCardTapResult>? onEmptySlotTap;

  /// height of this track
  final double trackHeight;

  final Duration duration;

  final Color? defaultColor;

  const TimelineEditorTrack({
    super.key,
    required this.scrollControllers,
    required this.boxes,
    required this.pixelsPerSeconds,
    required this.duration,
    this.trackHeight = 100,
    this.defaultColor,
    this.onEmptySlotTap,
  });

  @override
  _TimelineEditorTrackState createState() => _TimelineEditorTrackState();
}

class _TimelineEditorTrackState extends State<TimelineEditorTrack> {
  List<ITimelineEditorCard> boxes = [];
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    setup();
    _controller = widget.scrollControllers.addAndGet();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TimelineEditorTrack oldWidget) {
    if (boxes != widget.boxes) {
      setup();
    }
    super.didUpdateWidget(oldWidget);
  }

  void setup() {
    final targetBoxes = <ITimelineEditorCard>[];

    if (widget.boxes.length > 0) {
      final sortedStart = widget.boxes.toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      final blankFirstBox = TimelineEditorEmptyCard(
        start: Duration.zero,
        duration: sortedStart[0].start,
        onTap: widget.onEmptySlotTap,
      );
      targetBoxes.add(blankFirstBox);
      var i = 0;
      for (final box in sortedStart) {
        i++;

        final nextBoxTime =
            i < sortedStart.length ? sortedStart[i].start : widget.duration;
        targetBoxes.add(box);
        final end = box.start + (box.duration ?? Duration.zero);
        targetBoxes.add(TimelineEditorEmptyCard(
          start: end,
          duration: nextBoxTime - end,
          onTap: widget.onEmptySlotTap,
        ));
      }
    }

    boxes = targetBoxes;
  }

  double globalMoveSinceLastSend = 0;
  // void _onDragUpdate(DragUpdateDetails details, TimelineEditorBox box) {
  //   if (box.onMoved != null) {
  //     globalMoveSinceLastSend += details.delta.dx;
  //     var numberOfSeconds = details.delta.dx / widget.pixelsPerSeconds;
  //     var durationMove = durationFromSeconds(numberOfSeconds);
  //     if (box.start + durationMove < Duration.zero) {
  //       box.onMoved(Duration.zero);
  //     } else
  //       box.onMoved(durationMove);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.trackHeight,
      child: ListView.builder(
        key: widget.key,
        scrollDirection: Axis.horizontal,
        controller: _controller,
        itemCount: boxes.length,
        itemBuilder: (context, index) {
          final b = boxes[index];
          final availableSpace = boxes.length > index + 2
              ? boxes[index + 1].start
              : widget.duration;

          return b.build(
            context,
            pixelsPerSeconds: widget.pixelsPerSeconds,
            availableSpace: availableSpace,
          );
          // return GestureDetector(
          //   onTap:
          //       b.onTap == null ? null : () => b.onTap(b.start, b.duration),
          //   onHorizontalDragStart:
          //       b.onMoved == null ? null : (_) => globalMoveSinceLastSend = 0,
          //   onHorizontalDragUpdate:
          //       b.onMoved == null ? null : (d) => _onDragUpdate(d, b),
          //   onHorizontalDragEnd:
          //       b.onMovedEnd == null ? null : (_) => b.onMovedEnd(),
          //   child: b.build(context, widget.pixelsPerSeconds),
          // );
        },
      ),
    );
  }
}

// class TimelineLeading extends StatelessWidget {
//   final double trackHeight;
//   final Widget child;
//   const TimelineLeading({Key key, this.trackHeight, this.child}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }
