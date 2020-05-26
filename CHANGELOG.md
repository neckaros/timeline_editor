## 0.3.1
* Added helper to go from seconds double to Duration:
```dart
Duration durationFromSeconds(double seconds)
double durationToSeconds(Duration duration)
```
* Added possibility to customize timeline text theme and separator color:
```dart
class TimelineEditor extends StatefulWidget {
  ...
  /// Timeline time text theme. By default we use Theme.of(context).textTheme.bodyText1
  final TextTheme timelineTextStyle;

  /// Color used by the time separator in the timeline.
  /// By default we use Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black87
  final Color separatorColor;
  ...
}
```

## 0.3.0
* We now use duration instead of seconds ([Issue 1](https://github.com/neckaros/timeline_editor/issues/1))

## 0.2.2
* better time indicators
* height of track is not customizable

## 0.2.1
* fix scaling


## 0.2.0
Performance optimization
* position now takes a stream to rebuild as little as possible
* layout builder replaced by a cached version to avoid rebuilding too often
* you can now react to user clicking a time on the timeline ruler

## 0.1.0

* First release
