import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:timeline_editor/extensions.dart';

/// a box to be displayed in a [TimelineEditorTrack] with a [start] and a [duration]
class TimelineEditorCard extends ITimelineEditorCard {
  /// is the box selected
  final bool selected;

  /// When the user tap the box. Can be used to toggle selected status
  final VoidCallback onTap;

  /// this box is a separated and not a card
  final bool isSeparator;

  /// optional  custom child to display in this box
  final Widget child;

  /// background color of this box
  final Color color;

  /// optional border color when selected
  final Color borderColor;

  /// optional [PopupMenuEntry] list to display if a user long press this box
  final List<PopupMenuEntry> menuEntries;

  /// optional callback when a user click on one of the [menuEntries]
  final void Function(Object selectedItem) onSelectedMenuItem;

  /// optional callback that will activate the
  /// possibility of moving this box
  final void Function(Duration duration) onMovedDuration;

  /// optional callback that will activate the
  /// possibility of moving this box
  final void Function(Duration duration) onMovedStart;

  /// optional icon for [onMovedStart]
  final Icon onMovedStartIcon;

  /// optional icon for [onMovedDuration]
  final Icon onMovedDurationIcon;

  /// optional icon for [menuEntries]
  final Icon menuEntriesIcon;

  const TimelineEditorCard(Duration start,
      {Key key,
      Duration duration,
      this.isSeparator,
      this.selected = false,
      this.onTap,
      this.child,
      this.color,
      this.borderColor,
      this.menuEntries,
      this.onSelectedMenuItem,
      this.onMovedDuration,
      this.onMovedStart,
      this.onMovedStartIcon,
      this.onMovedDurationIcon,
      this.menuEntriesIcon})
      : super(key: key, start: start, duration: duration);

  @override
  Widget build(
    BuildContext context,
    double pixelsPerSeconds, {
    Duration availableSpace,
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
            child != null ? Positioned.fill(child: child) : Container(),
            if (selected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor != null ? borderColor : Colors.white, width: 6),
                  ),
                ),
              ),
            if (onMovedDuration != null && selected)
              GestureDetector(
                onHorizontalDragUpdate: (d) => onMovedDuration(
                    durationFromSeconds(d.delta.dx / pixelsPerSeconds)),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: Container(
                      color: borderColor != null ? borderColor : Colors.white,
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
                onHorizontalDragUpdate: (d) => onMovedStart(
                    durationFromSeconds(d.delta.dx / pixelsPerSeconds)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: Container(
                      color: borderColor != null ? borderColor : Colors.white,
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
            if (menuEntries != null && selected)
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: PopupMenuButton(
                    onSelected: (v) => onSelectedMenuItem(v),
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

class TimelineEditorEmptyCard extends ITimelineEditorCard {
  const TimelineEditorEmptyCard(Duration start, Duration duration, {Key key})
      : super(key: key, start: start, duration: duration);

  Widget build(
    BuildContext context,
    double pixelsPerSeconds, {
    Duration availableSpace,
  }) {
    return TimelineEditorSizedBox(
      duration: duration,
      pixelsPerSeconds: pixelsPerSeconds,
      child: Container(),
    );
  }
}

abstract class ITimelineEditorCard {
  final Key key;

  /// duration in seconds of the box. Let it null for continuous boxes
  final Duration duration;

  /// the start time in seconds of this box
  final Duration start;
  @mustCallSuper
  const ITimelineEditorCard({this.key, this.start, this.duration});

  Widget build(
    BuildContext context,
    double pixelsPerSeconds, {
    Duration availableSpace,
  });
}

class TimelineEditorSizedBox extends StatelessWidget {
  final Duration duration;
  final double pixelsPerSeconds;
  final double height;
  final Widget child;

  const TimelineEditorSizedBox({
    Key key,
    this.height,
    @required this.duration,
    @required this.pixelsPerSeconds,
    @required this.child,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var width = durationToSeconds(duration) * pixelsPerSeconds;
    return SizedBox(
      width: width > 0 ? width : 0,
      height: height ?? 100,
      child: child,
    );
  }
}

/// A track that can be used with the [timeline_editor] builder
class TimelineEditorTrack extends StatefulWidget {
  final List<ITimelineEditorCard> boxes;
  final double pixelsPerSeconds;
  final LinkedScrollControllerGroup scrollControllers;

  /// height of this track
  final double trackHeight;

  final Duration duration;

  final Color defaultColor;

  const TimelineEditorTrack(
      {Key key,
      @required this.scrollControllers,
      @required this.boxes,
      @required this.pixelsPerSeconds,
      @required this.duration,
      this.trackHeight = 100,
      this.defaultColor})
      : super(key: key);

  @override
  _TimelineEditorTrackState createState() => _TimelineEditorTrackState();
}

class _TimelineEditorTrackState extends State<TimelineEditorTrack> {
  List<ITimelineEditorCard> boxes;
  ScrollController _controller;

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
    List<ITimelineEditorCard> targetBoxes = List<ITimelineEditorCard>();

    if (widget.boxes != null && widget.boxes.length > 0) {
      var sortedStart = widget.boxes.toList();
      sortedStart.sort((a, b) => a.start.compareTo(b.start));
      var blankFirstBox = TimelineEditorEmptyCard(
        Duration.zero,
        sortedStart[0].start,
      );
      targetBoxes.add(blankFirstBox);
      var i = 0;
      for (var box in sortedStart) {
        i++;
        var nextBoxTime =
            i < sortedStart.length ? sortedStart[i].start : widget.duration;
        targetBoxes.add(box);
        var end = box.start + box.duration;
        targetBoxes.add(
          TimelineEditorEmptyCard(
            end,
            nextBoxTime - end,
          ),
        );
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
            var b = boxes[index];
            var availableSpace = boxes.length > index + 2
                ? boxes[index + 1].start
                : widget.duration;

            return b.build(context, widget.pixelsPerSeconds,
                availableSpace: availableSpace);
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
          }),
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
