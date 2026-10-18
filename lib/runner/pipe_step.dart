import 'package:build_pipe/utils/process.utils.dart';

/// A unit of work in the pipeline
///
/// Each step is shown as one line in the terminal and as one section in the log file
sealed class PipeStep {
  /// The name of the step shown to the user, e.g. `flutter clean` or `iOS`
  final String label;

  PipeStep(this.label);
}

/// A step that runs a single command and fails when the command exits with a non-zero code
class CommandStep extends PipeStep {
  final String executable;
  final List<String> arguments;

  /// The values replaced by `REDACTED` in the terminal and in the log file
  final List<String> redactions;

  CommandStep(
    super.label, {
    required this.executable,
    required this.arguments,
    this.redactions = const [],
  });

  /// Creates the step from a command written as a single string, such as the `build_command` of a platform
  ///
  /// The [extraArguments] are appended to the arguments of the command
  factory CommandStep.fromString(String label, String command, {List<String> extraArguments = const []}) {
    List<String> parts = ProcessHelper.splitCommand(command);
    return CommandStep(
      label,
      executable: parts.isEmpty ? "" : parts.first,
      arguments: [...parts.skip(1), ...extraArguments],
    );
  }
}

/// A step that runs Dart code, such as deleting a folder or calling an API
///
/// The step talks to the user only through the [StepContext], which is also how it runs any command
class ActionStep extends PipeStep {
  /// The work of the step. It returns the error when the step has failed
  final Future<StepError?> Function(StepContext context) action;

  ActionStep(super.label, this.action);
}

/// The reason a step has failed
class StepError {
  /// A short reason, e.g. `exited with code 1`
  final String message;

  /// The lines explaining the failure, e.g. the reasons given by App Store Connect
  final List<String> details;

  const StepError(this.message, {this.details = const []});

  /// Converts the outcome of a command to the error of the step, if the command has failed
  static StepError? fromCommand((CommandResult?, CommandError?) outcome) {
    if (outcome.$2 != null) {
      return StepError(outcome.$2!.message);
    }
    if (outcome.$1 != null && outcome.$1!.exitCode != 0) {
      return StepError("exited with code ${outcome.$1!.exitCode}");
    }
    return null;
  }
}

/// What a running step can do. Everything goes through the runner, so that it is shown and logged
abstract interface class StepContext {
  /// Runs a command as part of the step
  ///
  /// The output is shown and logged like that of a [CommandStep], and the [redactions] are applied to
  /// the command, its output, and the returned result
  Future<(CommandResult?, CommandError?)> runCommand(
    String executable,
    List<String> arguments, {
    List<String> redactions,
  });

  /// Shows what the step is doing at the moment, e.g. `Uploading the build file`
  void status(String text);

  /// Adds a line to the log file without showing it in the terminal
  void log(String line);

  /// Shows a warning under the step. The step still succeeds
  void warn(String message);
}

/// What happens to the rest of the run when a step of a stage fails
enum FailurePolicy {
  /// Skips the rest of the stage and all the stages after it.
  /// e.g. there is nothing to build when a pre-build step has failed
  stopRun,

  /// Runs the rest of the stage and the stages after it.
  /// e.g. a failed iOS build should not stop the Android build
  continueRun,
}

/// A titled group of steps, run in order
class PipeStage {
  final String title;
  final List<PipeStep> steps;
  final FailurePolicy onFailure;

  PipeStage(this.title, {required this.steps, this.onFailure = FailurePolicy.stopRun});
}
