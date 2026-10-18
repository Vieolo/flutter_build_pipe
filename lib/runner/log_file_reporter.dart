import 'dart:io';

import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_format.dart';

/// Writes the run to a log file, one section per step
///
/// Each line of a step starts with the time since the step has started. The lines are written as soon
/// as they arrive, so the log is complete up to the moment a run is stopped. A group has no section of its
/// own, since all its work is done by its steps
class LogFileReporter implements PipeReporter {
  static final String _runRule = "=" * 72;
  static final String _stepRule = "-" * 72;

  final RandomAccessFile _file;

  /// The first error that happened while writing. Nothing is written after it
  String? writeError;

  LogFileReporter._(this._file);

  /// Opens the log file at [path] for appending, creating it and its folders when they do not exist
  static (LogFileReporter?, String?) open(String path) {
    try {
      File file = File(path);
      file.parent.createSync(recursive: true);
      return (LogFileReporter._(file.openSync(mode: FileMode.append)), null);
    } on FileSystemException catch (e) {
      return (null, "${e.message}: ${e.path ?? path}");
    }
  }

  @override
  void onEvent(PipeEvent event) {
    switch (event) {
      case RunStarted started:
        PipeFormat.title(started.info).forEach(_write);
        _write("started: ${started.startedAt.toIso8601String()}");
        _write("");
      case StepStarted started:
        if (started.step.children.isEmpty) {
          _writeStepHeader(started.step);
          _write(_stepRule);
        }
      case StepStatusChanged changed:
        _writeTimed(changed.step, "» ${changed.text}");
      case StepWarned warned:
        _writeTimed(warned.step, "warning: ${warned.message}");
      case StepLogged logged:
        _writeTimed(logged.step, logged.line);
      case CommandStarted started:
        _writeTimed(started.step, "\$ ${started.commandLine}");
      case CommandOutput output:
        _writeTimed(output.step, "  ${output.line}");
      case CommandFinished finished:
        _writeTimed(finished.step, finished.error != null ? "  could not start: ${finished.error}" : "  exit code: ${finished.exitCode}");
      case StepFinished finished:
        if (finished.step.children.isEmpty) {
          _writeStepEnd(finished.step);
        }
      case RunFinished finished:
        _write(_runRule);
        _write(PipeFormat.summary(finished.result));
        for (StepState step in finished.result.allSteps) {
          _write("${"  " * (step.depth + 1)}${PipeFormat.symbol(step, useColor: false)} ${_stepName(step)}${_stepEnd(step)}");
        }
    }
  }

  @override
  Future<void> close() async {
    try {
      _file.closeSync();
    } on FileSystemException catch (e) {
      writeError ??= e.message;
    }
  }

  void _writeStepHeader(StepState step) {
    _write(_runRule);
    _write(_stepName(step));
  }

  void _writeStepEnd(StepState step) {
    if (step.status == StepStatus.skipped) {
      // A skipped step has not started, so it has no header yet
      _writeStepHeader(step);
      _write(_stepRule);
    } else {
      _write(_stepRule);
    }
    _write(step.status == StepStatus.skipped ? PipeFormat.outcome(step) : "${step.status.name}${_stepEnd(step)}");
    for (String detail in step.error?.details ?? <String>[]) {
      _write("  $detail");
    }
    _write("");
  }

  /// e.g. `[2] Pre-build › flutter clean`, or `[3.2] Build › Web › Cache bust` for a step of a group
  String _stepName(StepState step) => "[${step.number}] ${step.path.join(" › ")}";

  /// e.g. ` - 2.1s - exited with code 1`
  String _stepEnd(StepState step) {
    List<String> parts = [];
    if (step.status != StepStatus.skipped) {
      parts.add(PipeFormat.duration(step.elapsed));
    }
    String outcome = PipeFormat.outcome(step);
    if (outcome.isNotEmpty) {
      parts.add(outcome);
    }
    return parts.isEmpty ? "" : " - ${parts.join(" - ")}";
  }

  void _writeTimed(StepState step, String text) {
    String timestamp = PipeFormat.timestamp(step.elapsed);
    for (String line in text.split("\n")) {
      _write("$timestamp $line");
    }
  }

  void _write(String line) {
    if (writeError != null) return;
    try {
      _file.writeStringSync("$line\n");
    } on FileSystemException catch (e) {
      writeError = e.message;
    }
  }
}
