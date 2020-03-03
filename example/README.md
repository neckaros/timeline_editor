# timeline_editor_example

Demonstrates how to use the timeline_editor plugin.

```dart
@override
  Widget build(BuildContext context) {
    List<TimelineEditorContinuousBox> boxesContinuous = [
      TimelineEditorContinuousBox(
        0,
        color: Colors.deepOrange,
        child: const Image(image: const AssetImage('assets/image2.jpg')),
      ),
      TimelineEditorContinuousBox(
        box2Start,
        menuEntries: [
          PopupMenuItem<String>(child: Text('Delete'), value: 'deleted')
        ],
        onMoved: updateBox2,
        onSelectedMenuItem: (v) {
          print('Selected: $v');
          setState(() {
            deleted = true;
          });
        },
        onTap: (start, duration) =>
            print('tapped for $start to ${start + duration}'),
        color: Colors.black,
        child: const Image(image: const AssetImage('assets/image.jpg')),
      ),
    ];

    return MaterialApp(
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Timeline_editor example app'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(child: Center(child: Text('Timeline_editor example app'))),
            Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TimelineEditor(
                  position: position,
                  countTracks: 2,
                  trackBuilder: (track, pps, duration) => track == 1
                      ? TimelineEditorTrack(
                          defaultColor: Colors.green[700],
                          boxes: [
                            TimelineEditorBox(box1Start, 100,
                                onMoved: updateBox1,
                                color: Colors.blue,
                                onMovedEnd: () => print('end moved')),
                            TimelineEditorBox(157, 80),
                          ],
                          pixelsPerSeconds: pps,
                          durationInSeconds: duration,
                        )
                      : TimelineEditorTrack.fromContinuous(
                          continuousBoxes:
                              deleted ? [boxesContinuous[0]] : boxesContinuous,
                          pixelsPerSeconds: pps,
                          durationInSeconds: duration,
                        ),
                  durationInSeconds: 300,
                )),
          ],
        ),
      ),
    );
```
