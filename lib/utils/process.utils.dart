import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

/// The exit code and the output of a command that has run to completion
class CommandResult {
  /// The exit code of the command. Anything but `0` means that the command has failed
  final int exitCode;

  /// The stdout and stderr of the command, merged and split into lines
  final List<String> output;

  const CommandResult({required this.exitCode, required this.output});
}

/// The error of a command that could not be started, e.g. when the executable is not found
class CommandError {
  final String message;

  const CommandError(this.message);
}

/// The helper class for running commands
class ProcessHelper {
  /// Splitting the command while respecting the quoted strings
  static List<String> splitCommand(String command) {
    final List<String> result = [];
    final StringBuffer current = StringBuffer();
    bool inQuote = false;
    String quoteChar = '';

    for (int i = 0; i < command.length; i++) {
      final char = command[i];

      if (inQuote) {
        if (char == quoteChar) {
          inQuote = false;
          quoteChar = '';
        } else {
          current.write(char);
        }
      } else {
        if (char == '"' || char == "'") {
          inQuote = true;
          quoteChar = char;
        } else if (char == ' ') {
          if (current.isNotEmpty) {
            result.add(current.toString());
            current.clear();
          }
        } else {
          current.write(char);
        }
      }
    }

    if (current.isNotEmpty) {
      result.add(current.toString());
    }

    return result;
  }

  /// Runs a command to completion and returns its exit code and output
  ///
  /// The stdout and stderr of the command are merged and split into lines, and each line is passed
  /// to [onOutput] as soon as it arrives. This function neither prints nor logs anything.
  ///
  /// A command that exits with a non-zero code is not an error here, since only the caller knows
  /// whether the failure is acceptable. The error is returned only when the command could not be started
  ///
  /// The [environment] is added to the env variables of build_pipe for the command
  static Future<(CommandResult?, CommandError?)> run(
    String executable,
    List<String> arguments, {
    void Function(String line)? onOutput,
    Map<String, String>? environment,
  }) async {
    // `runInShell` allows commands like 'flutter pub get' work on Windows by running through cmd.
    // To avoid breaking the behavior on MacOS & Linux, we set the `runInShell` to true only
    // on the Windows
    bool runInShell = Platform.isWindows;

    Process process;
    try {
      process = await Process.start(executable, arguments, runInShell: runInShell, environment: environment);
    } on ProcessException catch (e) {
      return (null, CommandError("Could not start '$executable': ${e.message}"));
    }

    // A single malformed byte in the output of a command should not stop the build
    Encoding encoding = Platform.isWindows ? systemEncoding : const Utf8Codec(allowMalformed: true);

    // Both streams are read at the same time, otherwise a command that writes a lot to one of them
    // would block once the buffer of that stream is full
    List<String> output = [];
    Stream<String> lines = StreamGroup.merge([
      process.stdout.transform(encoding.decoder).transform(const LineSplitter()),
      process.stderr.transform(encoding.decoder).transform(const LineSplitter()),
    ]);
    await lines.forEach((String line) {
      output.add(line);
      onOutput?.call(line);
    });

    int exitCode = await process.exitCode;
    return (CommandResult(exitCode: exitCode, output: output), null);
  }
}
