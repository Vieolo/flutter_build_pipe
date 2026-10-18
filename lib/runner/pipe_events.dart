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

  /// The group the step belongs to, if any
  final StepState? parent;

  /// The steps of a [StepGroup], empty for the other steps
  final List<StepState> children = [];

  /// The position of the step in the run, e.g. `3` for the third step and `3.2` for the second step of its group
  final String number;

  /// Whether the step is the last of its stage, or of its group
  final bool isLast;

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
    required this.isLast,
    this.parent,
  });

  /// The step followed by all the steps of its group, and of their groups, in the order they are shown
  List<StepState> get tree => [this, for (StepState child in children) ...child.tree];

  /// The number of groups the step is in
  int get depth => parent == null ? 0 : parent!.depth + 1;

  /// The title of the stage, the labels of the groups the step is in, and the label of the step,
  /// e.g. `[Build, Web, Cache bust]`
  List<String> get path => parent == null ? [stage.title, step.label] : [...parent!.path, step.label];

  /// The warnings of the step and of all the steps of its group
  int get warningCount => warnings.length + children.fold(0, (int count, StepState s) => count + s.warningCount);

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
  /// The steps of the stages, in order. The steps of a group are its [StepState.children]
  final List<StepState> steps;
  final Duration elapsed;

  const PipeRunResult({required this.steps, required this.elapsed});

  /// All the steps of the run, including the steps of the groups, in the order they are shown
  List<StepState> get allSteps => [for (StepState step in steps) ...step.tree];

  List<StepState> get failedSteps => steps.where((StepState s) => s.status == StepStatus.failed).toList();

  List<StepState> get skippedSteps => steps.where((StepState s) => s.status == StepStatus.skipped).toList();

  int get warningCount => steps.fold(0, (int count, StepState s) => count + s.warningCount);

  bool get hasFailures => failedSteps.isNotEmpty;
}

/// Something that has happened during a run, sent by the runner to the reporters
sealed class PipeEvent {
  const PipeEvent();
}

/// What is being run, shown at the top of the output
class PipeRunInfo {
  /// The build_pipe command, e.g. `build`
  final String command;
  final String workflow;

  /// The version of the app, e.g. `1.2.0+12`
  final String version;

  const PipeRunInfo({required this.command, required this.workflow, required this.version});
}

/// Sent once, before the first step, with all the steps planned to run
class RunStarted extends PipeEvent {
  final PipeRunInfo info;

  /// The steps of the stages, in order. The steps of a group are its [StepState.children]
  final List<StepState> steps;
  final DateTime startedAt;

  const RunStarted({required this.info, required this.steps, required this.startedAt});

  /// All the steps of the run, including the steps of the groups, in the order they are shown
  List<StepState> get allSteps => [for (StepState step in steps) ...step.tree];
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
