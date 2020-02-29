import 'package:flutter/material.dart';

class TimelineEditorBox {
  final int duration;
  final int start;
  final Widget child;
  final Color color;
  final void Function(int start, int duration) onTap;

  const TimelineEditorBox(this.start, this.duration,
      {this.child, this.color, this.onTap});
}

class TimelineEditorContinuousBox {
  final int start;
  final Widget child;
  final Color color;
  final void Function(int start, int duration) onTap;

  const TimelineEditorContinuousBox(this.start,
      {this.child, this.color, this.onTap});
}

class TimelineEditorTrack extends StatefulWidget {
  final List<TimelineEditorBox> boxes;
  final List<TimelineEditorContinuousBox> continuousBoxes;
  final int pixelsPerSeconds;

  final int durationInSeconds;

  final Color defaultColor;

  const TimelineEditorTrack(
      {Key key,
      @required this.boxes,
      @required this.pixelsPerSeconds,
      @required this.durationInSeconds,
      this.defaultColor})
      : continuousBoxes = null,
        super(key: key);

  TimelineEditorTrack.fromContinuous(
      {Key key,
      @required this.continuousBoxes,
      @required this.pixelsPerSeconds,
      @required this.durationInSeconds,
      this.defaultColor})
      : boxes = null;

  @override
  _TimelineEditorTrackState createState() => _TimelineEditorTrackState();
}

class _TimelineEditorTrackState extends State<TimelineEditorTrack> {
  List<TimelineEditorBox> boxes;

  @override
  void initState() {
    setup();
    super.initState();
  }

  @override
  void didUpdateWidget(TimelineEditorTrack oldWidget) {
    if (oldWidget.continuousBoxes != widget.continuousBoxes ||
        oldWidget.boxes != oldWidget.boxes) super.didUpdateWidget(oldWidget);
  }

  void setup() {
    if (widget.boxes != null) {
      boxes = widget.boxes;
    } else {
      var sortedStart = widget.continuousBoxes.toList();
      sortedStart.sort((a, b) => b.start.compareTo(a.start));
      TimelineEditorContinuousBox previous;
      List<TimelineEditorBox> targetBoxes = List<TimelineEditorBox>();
      for (var box in sortedStart) {
        var duration = previous == null
            ? widget.durationInSeconds - box.start
            : previous.start - box.start;
        previous = box;
        targetBoxes.insert(
            0,
            TimelineEditorBox(box.start, duration,
                child: box.child, color: box.color, onTap: box.onTap));
      }
      boxes = targetBoxes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: boxes
          .map((b) => GestureDetector(
                onTap:
                    b.onTap == null ? null : () => b.onTap(b.start, b.duration),
                child: TimelineSlot(
                  pixelPerSeconds: widget.pixelsPerSeconds,
                  duration: b.duration,
                  start: b.start,
                  color: b.color ?? widget.defaultColor ?? Colors.red,
                  child: b.child,
                ),
              ))
          .toList(),
    );
  }
}

class TimelineSlot extends StatelessWidget {
  const TimelineSlot({
    Key key,
    @required this.pixelPerSeconds,
    @required this.duration,
    @required this.start,
    this.color,
    this.child,
  }) : super(key: key);

  final int pixelPerSeconds;
  final int duration;
  final int start;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: start.toDouble() * pixelPerSeconds),
      child: SizedBox(
        width: duration.toDouble() * pixelPerSeconds,
        height: 100,
        child: Card(
          margin: EdgeInsets.all(1.0),
          color: color,
          elevation: 2,
          child: child != null ? child : Container(),
        ),
      ),
    );
  }
}
