import 'dart:io';

import 'package:build_pipe/utils/config.utils.dart';

/// Utility class for generating the log files
class LogUtils {
  /// The starting lines of an action to be added to the log file
  /// The output will include the name and time of the action
  static List<String> getActionStartLines(String action) {
    return [
      "** action start ********************",
      "-- Running : $action",
      "-- Time    : ${DateTime.now().toIso8601String()}",
      "-- detail start ---------------------",
    ];
  }

  /// The ending lines of an action to be added to the log file
  static List<String> getActionEndLines() {
    return [
      "\n-- detail end -----------------------",
      "** action end **********************\n\n",
    ];
  }

  /// Takes a list of lines and appends it to the log file
  static Future<void> appendLogUsingStringList(
    BuildConfig config,
    List<String> logLines,
  ) async {
    if (!config.generateLog) return;

    File logFile = File(config.logFile);
    IOSink? logSink;
    bool alreadyExists = true;

    if (!(await logFile.exists())) {
      logFile = await File(config.logFile).create(recursive: true);
      alreadyExists = false;
    }

    logSink = logFile.openWrite(
      mode: alreadyExists ? FileMode.append : FileMode.write,
    );

    for (var line in logLines) {
      logSink.writeln(line);
    }
    await logSink.close();
  }
}
