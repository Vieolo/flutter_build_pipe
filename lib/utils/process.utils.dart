import 'dart:io';

import 'package:build_pipe/utils/config.utils.dart';

class ProcessHelper {
  static Future<int> runCommand({
    required String executable,
    required List<String> arguments,
    bool stdoutWrite = false,
    String? logFilePath,
    String? startMessage,
    String? successMessage,
    String? errorMessage,
    bool exitIfError = true,
  }) async {
    if (startMessage != null && startMessage.isNotEmpty) {
      print(startMessage);
    }

    // Handling the log file
    File? logFile;
    IOSink? logSink;
    bool alreadyExists = true;
    if (logFilePath != null && logFilePath.isNotEmpty) {
      logFile = File(logFilePath);
      if (!(await logFile.exists())) {
        logFile = await File(logFilePath).create(recursive: true);
        alreadyExists = false;
      }

      logSink = logFile.openWrite(mode: alreadyExists ? FileMode.append : FileMode.write);
      logSink.writeln("************************");
      logSink.writeln("-- Running : $executable ${arguments.join(" ")}");
      logSink.writeln("-- on      : ${DateTime.now().toIso8601String()}");
      logSink.writeln("-- output ---------------------\n");
    }
    var process = await Process.start(executable, arguments);
    await process.stdout.transform(systemEncoding.decoder).forEach((z) {
      if (stdoutWrite) {
        stdout.write(z);
      }
      if (logSink != null) {
        logSink.write(z);
      }
    });
    int exitCode = await process.exitCode;
    if (logSink != null) {
      logSink.writeln("\n-- output ---------------------");
      logSink.writeln("-- exit code: $exitCode");
      logSink.writeln("************************");
      await logSink.close();
    }

    if (exitCode != 0) {
      if (errorMessage != null && errorMessage.isNotEmpty) {
        print(errorMessage);
      }
      if (exitIfError) {
        exit(exitCode);
      }
    }

    if (successMessage != null && successMessage.isNotEmpty) {
      print(successMessage);
    }

    return exitCode;
  }

  static Future<int> runCommandUsingConfig({
    required String executable,
    required List<String> arguments,
    required BuildConfig config,
    String? startMessage,
    String? successMessage,
    String? errorMessage,
    bool exitIfError = true,
  }) async {
    return await runCommand(
      executable: executable,
      arguments: arguments,
      logFilePath: config.logFile,
      stdoutWrite: config.printstdout,
      errorMessage: errorMessage,
      exitIfError: exitIfError,
      startMessage: startMessage,
      successMessage: successMessage,
    );
  }
}
