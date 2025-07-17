class LogUtils {
  static List<String> getActionStartLines(String action) {
    return [
      "** action start ********************",
      "-- Running : $action",
      "-- Time    : ${DateTime.now().toIso8601String()}",
      "-- detail start ---------------------",
    ];
  }

  static List<String> getActionEndLines() {
    return [
      "\n-- detail end -----------------------",
      "** action end **********************\n\n",
    ];
  }
}
