import 'dart:io';

import 'package:build_pipe/utils/config.utils.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:build_pipe/utils/log.utils.dart';

class XCodeUtils {
  static Future<bool> deleteDerivedData(BuildConfig config, String derivedPath) async {
    bool deleted = false;
    List<String> logLines = LogUtils.getActionStartLines("Deleting the derived data of XCode");
    Console.logInfo("\nDeleting the XCode derived data...");

    var dir = Directory(derivedPath);
    if (!await dir.exists()) {
      logLines.addAll([
        "\n[error] The given path for XCode is invalid",
        "[path] $derivedPath\n",
      ]);
      Console.logError("The given path for XCode derived data is invalid -> $derivedPath");
    } else {
      try {
        dir.deleteSync(recursive: true);
        logLines.addAll([
          "\n[folder] $derivedPath",
          "[action] deleted",
        ]);
        Console.logSuccess("√ XCode derived data is deleted");
        deleted = true;
      } catch (e) {
        logLines.addAll([
          "\n[error] ${e.toString()}",
          "[path] $derivedPath\n",
        ]);
        Console.logError("There was an error deleting the derived data -> ${e.toString()}");
      }
    }

    logLines.addAll(LogUtils.getActionEndLines());
    await LogUtils.appendLogUsingStringList(config, logLines);
    return deleted;
  }
}
