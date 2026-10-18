import 'dart:convert';
import 'dart:io';

import 'package:mansil/mansil.dart';

/// Handles the printing to the terminal, outside of a run
///
/// The messages before and after a run, such as the errors of the config, are printed here. During a
/// run, everything goes through the reporters instead
class Console {
  /// Whether to print each message as a JSON line, for the `json` output. Set once by the command,
  /// before anything is printed, so that the stdout holds nothing but JSON
  static bool json = false;

  /// Logs a text in red
  static void logError(String message) => _log("error", message, Mansil.redFg);

  /// Logs a text in green
  static void logSuccess(String message) => _log("success", message, Mansil.greenFg);

  /// Logs a text in yellow
  static void logWarning(String message) => _log("warning", message, Mansil.yellowFg);

  /// Logs a text in bold white
  static void logInfo(String message) => _log("info", message, Mansil.whiteFg);

  static void _log(String level, String message, String color) {
    if (json) {
      SafeStdout.instance.writeln(jsonEncode({"event": "message", "level": level, "text": message.trim()}));
    } else if (stdout.supportsAnsiEscapes) {
      SafeStdout.instance.writeln("$color${Mansil.bold}$message${Mansil.reset}");
    } else {
      // The escape codes would show up as text in a file or a CI log
      SafeStdout.instance.writeln(message);
    }
  }
}

/// The stdout, where the writes stop quietly once they fail, instead of stopping the run
///
/// A write fails when the stdout is a pipe whose reader has gone away, e.g. `... | head -n 5`. The
/// run still finishes, its exit code is the same, and the log file still has all of it
class SafeStdout implements StringSink {
  static final SafeStdout instance = SafeStdout._();

  bool _failed = false;

  SafeStdout._() {
    // The error of a failed write is also given to `done`, where nothing else would handle it
    stdout.done.ignore();
  }

  @override
  void write(Object? object) => _guard(() => stdout.write(object));

  @override
  void writeln([Object? object = ""]) => _guard(() => stdout.writeln(object));

  @override
  void writeAll(Iterable<Object?> objects, [String separator = ""]) => _guard(() => stdout.writeAll(objects, separator));

  @override
  void writeCharCode(int charCode) => _guard(() => stdout.writeCharCode(charCode));

  void _guard(void Function() write) {
    if (_failed) return;
    try {
      write();
    } on Exception {
      _failed = true;
    } on StateError {
      // The stdout is closed after its first failed write
      _failed = true;
    }
  }
}
