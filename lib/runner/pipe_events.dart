import 'package:build_pipe/runner/pipe_step.dart';

/// Where a step is in its run
enum StepStatus { pending, running, succeeded, failed, skipped }

/// The state of a step during and after the run, shared with the reporters
///
/// Only the runner changes the state, the reporters read it
class StepState {
  /// The number of output lines kept for showing a failure
  static const int recentOutputLimit = 20;

  final PipeStep step;
  final PipeStage stage;

  /// The position of the step in the run, starting from 1
  final int number;
  final bool isFirstInStage;
  final bool isLastInStage;

  StepStatus status = StepStatus.pending;

  /// What the step is doing at the moment, as reported by the step itself
  String? statusText;

  /// Set when the step has failed
  StepError? error;

  /// Set when the step has been skipped
  String? skipReason;

  final List<String> warnings = [];
  final List<String> _recentOutput = [];
  final Stopwatch _stopwatch = Stopwatch();

  StepState({
    required this.step,
    required this.stage,
    required this.number,
    required this.isFirstInStage,
    required this.isLastInStage,
  });

  /// The time the step has been running for, or took to run once it is finished
  Duration get elapsed => _stopwatch.elapsed;

  /// The last lines of the output of the commands run by the step, at most [recentOutputLimit]
  List<String> get recentOutput => List.unmodifiable(_recentOutput);

  bool get isFinished => status == StepStatus.succeeded || status == StepStatus.failed || status == StepStatus.skipped;

  /// Called by the runner when the step starts
  void start() {
    status = StepStatus.running;
    _stopwatch.start();
  }

  /// Called by the runner when the step ends, with the [error] if the step has failed
  void finish(StepError? error) {
    _stopwatch.stop();
    this.error = error;
    statusText = null;
    status = error == null ? StepStatus.succeeded : StepStatus.failed;
  }

  /// Called by the runner instead of [start] and [finish] when the step is not run
  void skip(String reason) {
    skipReason = reason;
    status = StepStatus.skipped;
  }

  /// Called by the runner for each line of the output of a command
  void addOutput(String line) {
    _recentOutput.add(line);
    if (_recentOutput.length > recentOutputLimit) {
      _recentOutput.removeAt(0);
    }
  }
}

/// The outcome of a run
class PipeRunResult {
  /// All the steps of the run, in order
  final List<StepState> steps;
  final Duration elapsed;

  const PipeRunResult({required this.steps, required this.elapsed});

  List<StepState> get failedSteps => steps.where((StepState s) => s.status == StepStatus.failed).toList();

  List<StepState> get skippedSteps => steps.where((StepState s) => s.status == StepStatus.skipped).toList();

  int get warningCount => steps.fold(0, (int count, StepState s) => count + s.warnings.length);

  bool get hasFailures => failedSteps.isNotEmpty;
}

/// Something that has happened during a run, sent by the runner to the reporters
sealed class PipeEvent {
  const PipeEvent();
}

/// Sent once, before the first step, with all the steps planned to run
class RunStarted extends PipeEvent {
  final String title;
  final List<StepState> steps;
  final DateTime startedAt;

  const RunStarted({required this.title, required this.steps, required this.startedAt});
}

class StepStarted extends PipeEvent {
  final StepState step;

  const StepStarted(this.step);
}

/// The step has reported what it is doing, which is also in `step.statusText`
class StepStatusChanged extends PipeEvent {
  final StepState step;
  final String text;

  const StepStatusChanged(this.step, this.text);
}

class StepWarned extends PipeEvent {
  final StepState step;
  final String message;

  const StepWarned(this.step, this.message);
}

/// A line meant only for the log file
class StepLogged extends PipeEvent {
  final StepState step;
  final String line;

  const StepLogged(this.step, this.line);
}

class CommandStarted extends PipeEvent {
  final StepState step;

  /// The command and its arguments, redacted
  final String commandLine;

  const CommandStarted(this.step, this.commandLine);
}

/// A line of the output of a command, redacted
class CommandOutput extends PipeEvent {
  final StepState step;
  final String line;

  const CommandOutput(this.step, this.line);
}

/// Has the [exitCode] when the command has run, or the [error] when it could not be started
class CommandFinished extends PipeEvent {
  final StepState step;
  final int? exitCode;
  final String? error;

  const CommandFinished(this.step, {this.exitCode, this.error});
}

/// The step has succeeded, failed, or been skipped, as told by `step.status`
class StepFinished extends PipeEvent {
  final StepState step;

  const StepFinished(this.step);
}

/// Sent once, after the last step
class RunFinished extends PipeEvent {
  final PipeRunResult result;

  const RunFinished(this.result);
}

/// Shows or records the events of a run, e.g. in the terminal or in the log file
abstract interface class PipeReporter {
  void onEvent(PipeEvent event);

  /// Called once after [RunFinished], to release whatever the reporter holds
  Future<void> close();
}
