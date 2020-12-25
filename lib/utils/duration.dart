String formatDuration(Duration duration) {
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  final hours = duration.inHours;
  var minutes = duration.inMinutes;
  if (minutes > 75) {
    minutes = minutes - (hours * 60);
    var seconds = duration.inSeconds - (minutes * 60);
    return '${hours}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  } else {
    var seconds = duration.inSeconds - (minutes * 60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
