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
    bool? clearStartMessage,
  }) async {
    if (startMessage != null && startMessage.isNotEmpty) {
      Console.logInfo(startMessage);
    }

    // Handling the log file
    File? logFile;
    IOSink? logSink;
    bool alreadyExists = true;
    List<String> rawOutput = [];

    // Getting or creating the log file
    if (logFilePath != null && logFilePath.isNotEmpty) {
      try {
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
      } catch (e) {
        Console.logError("There was an unexpected error preparing the log file!");
        Console.logError(e.toString());
      }
    }

    // Running the command
    // runInShell: true allows commands like 'flutter pub get' work on Windows by running through cmd.
    var process = await Process.start(executable, arguments, runInShell: true);
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

    // Writing the end of the command to the logfile
    if (logSink != null) {
      logSink.writeln("\n-- output end -----------------------");
      logSink.writeln("-- exit code: $exitCode");
      logSink.writeln("** command end **********************\n\n");
      await logSink.close();
    }

    if (clearStartMessage == true) {
      stdout.write('\x1B[1A\x1B[2K\r');
    }

    // The command has failed
    // If the failure is not acceptable (by passing the `exitIfError`),
    // then we terminate the run
    if (exitCode != 0) {
      if (errorMessage != null && errorMessage.isNotEmpty) {
        Console.logError(errorMessage);
      }
      if (exitIfError) {
        exit(exitCode);
      }
    }

    // Logging the success message
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
    bool? clearStartMessage,
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
      clearStartMessage: clearStartMessage,
    );
  }
}
