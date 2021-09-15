class PlayBackBean {
  int startTime;
  int endTime;
  String formatedStarTime;
  String formatedEndTime;

  PlayBackBean(
      {this.startTime,
        this.endTime,
        this.formatedStarTime,
        this.formatedEndTime});

  static Duration parseDuration(String s) {
    int hours = 0;
    int minutes = 0;
    int micros;
    List<String> parts = s.split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
    return Duration(hours: hours, minutes: minutes, microseconds: micros);
  }
}