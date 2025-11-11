import 'dart:io';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/utils/console.utils.dart';

String _redact(String output, List<String>? redactions) {
  if (redactions == null || redactions.isEmpty) return output;

  String o = output;

  for (var red in redactions) {
    o = o.replaceAll(red, "REDACTED");
  }
  return o;
}

/// The helper class for running commands
class ProcessHelper {
  /// Runs a given command and handles the logging
  static Future<(int, List<String>)> runCommand({
    required String executable,
    required List<String> arguments,
    bool stdoutWrite = false,
    String? logFilePath,
    String? startMessage,
    String? successMessage,
    String? errorMessage,
    bool exitIfError = true,
    List<String>? redactions,
  }) async {
    if (startMessage != null && startMessage.isNotEmpty) {
      Console.logInfo(startMessage);
    }

    // Handling the log file
    File? logFile;
    IOSink? logSink;
    bool alreadyExists = true;
    List<String> rawOutput = [];
    if (logFilePath != null && logFilePath.isNotEmpty) {
      logFile = File(logFilePath);
      if (!(await logFile.exists())) {
        logFile = await File(logFilePath).create(recursive: true);
        alreadyExists = false;
      }

      logSink = logFile.openWrite(
        mode: alreadyExists ? FileMode.append : FileMode.write,
      );
      logSink.writeln("** command start ********************");
      logSink.writeln(_redact("-- Running : $executable ${arguments.join(" ")}", redactions));
      logSink.writeln("-- Time    : ${DateTime.now().toIso8601String()}");
      logSink.writeln("-- output start ---------------------\n");
    }
    var process = await Process.start(executable, arguments);
    await process.stdout.transform(systemEncoding.decoder).forEach((z) {
      if (stdoutWrite) {
        stdout.write(z);
      }
      if (logSink != null) {
        logSink.write(_redact(z, redactions));
      }
      rawOutput.add(z);
    });
    int exitCode = await process.exitCode;
    if (logSink != null) {
      logSink.writeln("\n-- output end -----------------------");
      logSink.writeln("-- exit code: $exitCode");
      logSink.writeln("** command end **********************\n\n");
      await logSink.close();
    }

    if (exitCode != 0) {
      if (errorMessage != null && errorMessage.isNotEmpty) {
        Console.logError(errorMessage);
      }
      if (exitIfError) {
        exit(exitCode);
      }
    }

    if (exitCode == 0 && successMessage != null && successMessage.isNotEmpty) {
      Console.logSuccess(successMessage);
    }

    return (exitCode, rawOutput);
  }

  /// Calls the `runCommand` function of this class
  /// under the hood but instead of taking all the
  /// arguments, it uses the user provided config to
  /// pass the necessary arguments
  static Future<(int, List<String>)> runCommandUsingConfig({
    required String executable,
    required List<String> arguments,
    required BPConfig config,
    String? startMessage,
    String? successMessage,
    String? errorMessage,
    bool exitIfError = true,
    List<String>? redactions,
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
      redactions: redactions,
    );
  }
}
