import 'package:flutter/material.dart';

class TimelineEditorBox {
  final double duration;
  final double start;
  final Widget child;
  final Color color;
  final List<PopupMenuEntry> menuEntries;
  final void Function(Object selectedItem) onSelectedMenuItem;
  final void Function(double start, double duration) onTap;

  final void Function(double seconds) onMoved;
  final VoidCallback onMovedEnd;

  const TimelineEditorBox(this.start, this.duration,
      {this.child,
      this.color,
      this.onTap,
      this.menuEntries,
      this.onSelectedMenuItem,
      this.onMoved,
      this.onMovedEnd});
}

class TimelineEditorContinuousBox {
  final double start;
  final Widget child;
  final Color color;
  final List<PopupMenuEntry> menuEntries;
  final void Function(Object selectedItem) onSelectedMenuItem;
  final void Function(double start, double duration) onTap;
  final void Function(double seconds) onMoved;
  final VoidCallback onMovedEnd;

  const TimelineEditorContinuousBox(this.start,
      {this.child,
      this.color,
      this.onTap,
      this.menuEntries,
      this.onSelectedMenuItem,
      this.onMoved,
      this.onMovedEnd});
}

class TimelineEditorTrack extends StatefulWidget {
  final List<TimelineEditorBox> boxes;
  final List<TimelineEditorContinuousBox> continuousBoxes;
  final int pixelsPerSeconds;

  final double durationInSeconds;

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

  var _tapPosition;

  @override
  void initState() {
    setup();
    super.initState();
  }

  @override
  void didUpdateWidget(TimelineEditorTrack oldWidget) {
    if (oldWidget.continuousBoxes != widget.continuousBoxes ||
        boxes != widget.boxes) {
      setup();
    }
    super.didUpdateWidget(oldWidget);
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
            TimelineEditorBox(
              box.start,
              duration,
              child: box.child,
              color: box.color,
              onTap: box.onTap,
              menuEntries: box.menuEntries,
              onSelectedMenuItem: box.onSelectedMenuItem,
              onMoved: box.onMoved,
              onMovedEnd: box.onMovedEnd,
            ));
      }
      boxes = targetBoxes;
    }
  }

  void _showCustomMenu(TimelineEditorBox box) async {
    if (box.menuEntries != null) {
      final RenderBox overlay = Overlay.of(context).context.findRenderObject();

      var result = await showMenu(
          context: context,
          items: box.menuEntries, //<PopupMenuEntry>[PlusMinusEntry()],
          position: RelativeRect.fromRect(
              _tapPosition & Size(40, 40), // smaller rect, the touch area
              Offset.zero & overlay.size // Bigger rect, the entire screen
              ));
      if (box.onSelectedMenuItem != null) {
        box.onSelectedMenuItem(result);
      }
    }
  }

  double globalMoveSinceLastSend = 0;
  void _onDragUpdate(DragUpdateDetails details, TimelineEditorBox box) {
    if (box.onMoved != null) {
      globalMoveSinceLastSend += details.delta.dx;
      var numberOfSeconds = details.delta.dx / widget.pixelsPerSeconds;
      box.onMoved(numberOfSeconds);
    }
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: boxes
          .map((b) => GestureDetector(
                onTap:
                    b.onTap == null ? null : () => b.onTap(b.start, b.duration),
                onLongPress:
                    b.menuEntries == null ? null : () => _showCustomMenu(b),
                onTapDown: _storePosition,
                onHorizontalDragStart: b.onMoved == null
                    ? null
                    : (_) => globalMoveSinceLastSend = 0,
                onHorizontalDragUpdate:
                    b.onMoved == null ? null : (d) => _onDragUpdate(d, b),
                onHorizontalDragEnd:
                    b.onMovedEnd == null ? null : (_) => b.onMovedEnd(),
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
  final double duration;
  final double start;
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
