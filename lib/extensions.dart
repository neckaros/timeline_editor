Duration durationFromSeconds(double seconds) =>
    Duration(microseconds: (seconds * 1000000).round());

double durationToSeconds(Duration duration) =>
    duration.inMicroseconds / 1000000;
