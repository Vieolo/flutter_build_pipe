import 'dart:io';

import 'package:build_pipe/utils/config.utils.dart';

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

  static Future<void> appendLogUsingStringList(BuildConfig config, List<String> logLines) async {
    if (!config.generateLog) return;

    File logFile = File(config.logFile);
    IOSink? logSink;
    bool alreadyExists = true;

    if (!(await logFile.exists())) {
      logFile = await File(config.logFile).create(recursive: true);
      alreadyExists = false;
    }

    logSink = logFile.openWrite(mode: alreadyExists ? FileMode.append : FileMode.write);

    for (var line in logLines) {
      logSink.writeln(line);
    }
    await logSink.close();
  }
}
