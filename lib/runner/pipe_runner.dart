import 'dart:io';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/runner/interactive_reporter.dart';
import 'package:build_pipe/runner/json_reporter.dart';
import 'package:build_pipe/runner/log_file_reporter.dart';
import 'package:build_pipe/runner/output_mode.dart';
import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:build_pipe/runner/plain_reporter.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:build_pipe/utils/process.utils.dart';
import 'package:path/path.dart' as p;

/// Runs the stages of a pipeline in order and reports everything that happens to the reporters
///
/// The runner is the only place that decides what happens after a failure, and the steps
/// themselves neither print nor log anything
class PipeRunner {
  final List<PipeReporter> reporters;

  PipeRunner(this.reporters);

  /// Runs the [stages] with the reporters chosen by the [config], and returns the outcome
  ///
  /// The [command] is the name of the build_pipe command, e.g. `build`
  static Future<PipeRunResult> runWithConfig(
    BPConfig config, {
    required String command,
    required List<PipeStage> stages,
  }) async {
    List<PipeReporter> reporters = [];

    LogFileReporter? logReporter;
    String? logFilePath;
    if (config.generateLog) {
      (LogFileReporter?, String?) opened = LogFileReporter.open(config.logFile);
      if (opened.$2 != null) {
        Console.logWarning("The log file could not be created, so this run will not be logged -> ${opened.$2}");
      } else {
        logReporter = opened.$1;
        logFilePath = p.relative(config.logFile);
        reporters.add(logReporter!);
      }
    }

    reporters.add(switch (config.output.resolve()) {
      OutputMode.interactive => InteractiveReporter(logFilePath: logFilePath),
      OutputMode.json => JsonReporter(logFilePath: logFilePath),
      OutputMode.verbose => PlainReporter(printOutput: true, useColor: stdout.supportsAnsiEscapes, logFilePath: logFilePath),
      // `auto` is already resolved to one of the other modes
      OutputMode.plain || OutputMode.auto => PlainReporter(printOutput: false, useColor: stdout.supportsAnsiEscapes, logFilePath: logFilePath),
    });

    PipeRunInfo info = PipeRunInfo(command: command, workflow: config.workflowName, version: "${config.version}+${config.buildVersion}");
    PipeRunResult result = await PipeRunner(reporters).run(info, stages);

    if (logReporter?.writeError != null) {
      Console.logWarning("Parts of this run could not be written to the log file -> ${logReporter!.writeError}");
    }
    return result;
  }

  /// Runs the [stages] in order and returns the outcome
  ///
  /// When a step fails, the [FailurePolicy] of its stage decides whether the rest of the run is skipped
  Future<PipeRunResult> run(PipeRunInfo info, List<PipeStage> stages) async {
    List<StepState> states = [];
    for (PipeStage stage in stages) {
      for (int i = 0; i < stage.steps.length; i++) {
        states.add(_createState(stage.steps[i], stage, null, "${states.length + 1}", i == stage.steps.length - 1));
      }
    }

    Stopwatch stopwatch = Stopwatch()..start();
    _emit(RunStarted(info: info, steps: states, startedAt: DateTime.now()));

    bool stopped = false;
    for (StepState state in states) {
      if (stopped) {
        _skip(state, "an earlier step has failed");
        continue;
      }

      await _runStep(state);
      if (state.status == StepStatus.failed && state.stage.onFailure == FailurePolicy.stopRun) {
        stopped = true;
      }
    }

    PipeRunResult result = PipeRunResult(steps: states, elapsed: stopwatch.elapsed);
    _emit(RunFinished(result));
    for (PipeReporter reporter in reporters) {
      await reporter.close();
    }
    return result;
  }

  /// Creates the state of the [step], along with the states of its steps when it is a group
  StepState _createState(PipeStep step, PipeStage stage, StepState? parent, String number, bool isLast) {
    StepState state = StepState(step: step, stage: stage, parent: parent, number: number, isLast: isLast);
    if (step is StepGroup) {
      for (int i = 0; i < step.steps.length; i++) {
        state.children.add(_createState(step.steps[i], stage, state, "$number.${i + 1}", i == step.steps.length - 1));
      }
    }
    return state;
  }

  Future<void> _runStep(StepState state) async {
    state.start();
    _emit(StepStarted(state));

    StepError? error = switch (state.step) {
      StepGroup _ => await _runGroup(state),
      ActionStep step => await _runAction(state, step.action),
      CommandStep step => await _runAction(
        state,
        (StepContext context) async => StepError.fromCommand(
          await context.runCommand(step.executable, step.arguments, redactions: step.redactions),
        ),
      ),
    };

    state.finish(error);
    _emit(StepFinished(state));
  }

  /// Runs the steps of a group in order, until one of them fails
  Future<StepError?> _runGroup(StepState group) async {
    StepState? failed;
    for (StepState child in group.children) {
      if (failed != null) {
        _skip(child, "${failed.step.label} has failed");
        continue;
      }
      await _runStep(child);
      if (child.status == StepStatus.failed) {
        failed = child;
      }
    }
    return failed == null ? null : StepError("${failed.step.label} has failed");
  }

  /// Runs the work of a step that is not a group
  Future<StepError?> _runAction(StepState state, Future<StepError?> Function(StepContext context) action) async {
    _RunnerStepContext context = _RunnerStepContext(this, state);
    try {
      return await action(context);
    } catch (e, stackTrace) {
      // The steps return their errors as values, so getting here is a bug in the step.
      // Catching it keeps the rest of the run, its summary, and the log file intact
      context.log("Unexpected error: $e\n$stackTrace");
      return StepError("unexpected error: $e");
    }
  }

  /// Marks the [state], and all the steps of its group, as skipped
  void _skip(StepState state, String reason) {
    state.skip(reason);
    _emit(StepFinished(state));
    for (StepState child in state.children) {
      _skip(child, reason);
    }
  }

  void _emit(PipeEvent event) {
    for (PipeReporter reporter in reporters) {
      reporter.onEvent(event);
    }
  }
}

/// Replaces each of the [redactions] in the [text] with `REDACTED`
String _redact(String text, List<String> redactions) {
  String redacted = text;
  for (String value in redactions) {
    // Replacing an empty string would put `REDACTED` between every character
    if (value.isEmpty) continue;
    redacted = redacted.replaceAll(value, "REDACTED");
  }
  return redacted;
}

/// Quotes an argument that contains spaces, so that the shown command reads like the one that is run
String _quoteArgument(String argument) {
  if (argument.isNotEmpty && !argument.contains(RegExp(r'\s'))) return argument;
  return '"${argument.replaceAll('"', r'\"')}"';
}

/// The [StepContext] given to the steps, turning what they do into events
class _RunnerStepContext implements StepContext {
  final PipeRunner _runner;
  final StepState _state;

  _RunnerStepContext(this._runner, this._state);

  @override
  Future<(CommandResult?, CommandError?)> runCommand(
    String executable,
    List<String> arguments, {
    List<String> redactions = const [],
  }) async {
    _runner._emit(CommandStarted(_state, _redact([executable, ...arguments].map(_quoteArgument).join(" "), redactions)));

    List<String> redactedOutput = [];
    (CommandResult?, CommandError?) outcome = await ProcessHelper.run(
      executable,
      arguments,
      onOutput: (String line) {
        String redacted = _redact(line, redactions);
        redactedOutput.add(redacted);
        _state.addOutput(redacted);
        _runner._emit(CommandOutput(_state, redacted));
      },
    );

    if (outcome.$2 != null) {
      CommandError error = CommandError(_redact(outcome.$2!.message, redactions));
      _runner._emit(CommandFinished(_state, error: error.message));
      return (null, error);
    }

    int exitCode = outcome.$1!.exitCode;
    _runner._emit(CommandFinished(_state, exitCode: exitCode));
    return (CommandResult(exitCode: exitCode, output: redactedOutput), null);
  }

  @override
  void status(String text) {
    _state.statusText = text;
    _runner._emit(StepStatusChanged(_state, text));
  }

  @override
  void log(String line) {
    _runner._emit(StepLogged(_state, line));
  }

  @override
  void warn(String message) {
    _state.warnings.add(message);
    _runner._emit(StepWarned(_state, message));
  }
}
