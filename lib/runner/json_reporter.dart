import 'dart:convert';

import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/utils/console.utils.dart';

/// Writes the run as JSON Lines, one object per event, for scripts and agents
///
/// Each object is written as soon as its event happens, so a run that is stopped still leaves valid
/// lines behind, and the last line of a finished run holds its whole outcome. The output of the
/// commands is not written, since it can be thousands of lines. The end of the output of a failed
/// step is in its `step_finished` event, and the whole output is in the log file.
///
/// The format is documented in `doc/output/output_intro.md`. New events and fields can be added freely,
/// while removing a field or changing its meaning bumps the [schema] and is a breaking change
class JsonReporter implements PipeReporter {
  static const int schema = 1;

  final String? logFilePath;
  final StringSink _out;

  /// The [out] defaults to the stdout, and is replaced in the tests
  JsonReporter({this.logFilePath, StringSink? out}) : _out = out ?? SafeStdout.instance;

  @override
  void onEvent(PipeEvent event) {
    Map<String, Object?>? json = switch (event) {
      RunStarted started => {
        "event": "run_started",
        "schema": schema,
        "command": started.info.command,
        "workflow": started.info.workflow,
        "version": started.info.version,
        "started_at": started.startedAt.toIso8601String(),
        "steps": [for (StepState step in started.allSteps) _stepId(step)],
      },
      StepStarted started => {"event": "step_started", ..._stepId(started.step)},
      StepStatusChanged changed => {"event": "step_status", ..._stepId(changed.step), "text": changed.text},
      StepWarned warned => {"event": "step_warning", ..._stepId(warned.step), "message": warned.message},
      CommandStarted started => {"event": "command_started", ..._stepId(started.step), "command": started.commandLine},
      CommandFinished finished => {
        "event": "command_finished",
        ..._stepId(finished.step),
        if (finished.exitCode != null) "exit_code": finished.exitCode,
        if (finished.error != null) "error": finished.error,
      },
      StepFinished finished => {"event": "step_finished", ..._stepOutcome(finished.step)},
      RunFinished finished => {
        "event": "run_finished",
        "status": finished.result.hasFailures ? "failed" : "succeeded",
        "elapsed_ms": finished.result.elapsed.inMilliseconds,
        "steps": finished.result.steps.length,
        "failed": finished.result.failedSteps.length,
        "skipped": finished.result.skippedSteps.length,
        "warnings": finished.result.warningCount,
        if (logFilePath != null) "log_file": logFilePath,
        "results": [for (StepState step in finished.result.allSteps) _stepOutcome(step)],
      },
      // Only meant for the log file
      StepLogged _ || CommandOutput _ => null,
    };

    if (json != null) {
      _out.writeln(jsonEncode(json));
    }
  }

  @override
  Future<void> close() async {}

  /// What identifies a step. The labels can repeat, e.g. each platform with extra steps has a `Build` step
  Map<String, Object?> _stepId(StepState step) => {"number": step.number, "path": step.path};

  Map<String, Object?> _stepOutcome(StepState step) {
    return {
      ..._stepId(step),
      "status": step.status.name,
      if (step.status != StepStatus.skipped) "elapsed_ms": step.elapsed.inMilliseconds,
      if (step.error != null) "error": step.error!.message,
      if (step.error != null && step.error!.details.isNotEmpty) "details": step.error!.details,
      if (step.skipReason != null) "skip_reason": step.skipReason,
      if (step.warnings.isNotEmpty) "warnings": step.warnings,
      if (step.status == StepStatus.failed && step.recentOutput.isNotEmpty) "recent_output": step.recentOutput,
    };
  }
}
