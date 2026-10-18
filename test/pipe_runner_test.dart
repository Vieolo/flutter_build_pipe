import 'dart:io';

import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_runner.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:build_pipe/utils/process.utils.dart';
import 'package:test/test.dart';

/// Keeps every event, to check what the runner has reported
class RecordingReporter implements PipeReporter {
  final List<PipeEvent> events = [];
  bool closed = false;

  @override
  void onEvent(PipeEvent event) => events.add(event);

  @override
  Future<void> close() async => closed = true;

  List<String> get commandLines => [
    for (PipeEvent e in events)
      if (e is CommandStarted) e.commandLine,
  ];

  List<String> get outputLines => [
    for (PipeEvent e in events)
      if (e is CommandOutput) e.line,
  ];
}

/// A step running `test/sample/echo_and_exit.dart`
CommandStep echoStep(String label, int exitCode, [List<String> lines = const [], List<String> redactions = const []]) {
  return CommandStep(
    label,
    executable: Platform.resolvedExecutable,
    arguments: ["test/sample/echo_and_exit.dart", "$exitCode", ...lines],
    redactions: redactions,
  );
}

ActionStep succeedingAction(String label) => ActionStep(label, (StepContext context) async => null);

ActionStep failingAction(String label) => ActionStep(label, (StepContext context) async => const StepError("failed on purpose"));

Map<String, StepStatus> statuses(PipeRunResult result) => {for (StepState s in result.steps) s.step.label: s.status};

void main() {
  group('PipeRunner', () {
    test('runs all the steps in order and reports the run', () async {
      RecordingReporter reporter = RecordingReporter();
      PipeRunResult result = await PipeRunner([reporter]).run("title", [
        PipeStage(
          "First",
          steps: [
            echoStep("a", 0, ["hello"]),
            succeedingAction("b"),
          ],
        ),
        PipeStage("Empty", steps: []),
        PipeStage("Second", steps: [succeedingAction("c")]),
      ]);

      expect(result.hasFailures, isFalse);
      expect(result.steps.map((StepState s) => s.number), [1, 2, 3]);
      expect(statuses(result), {"a": StepStatus.succeeded, "b": StepStatus.succeeded, "c": StepStatus.succeeded});
      expect(reporter.events.first, isA<RunStarted>());
      expect(reporter.events.last, isA<RunFinished>());
      expect(reporter.events.whereType<StepStarted>().map((StepStarted e) => e.step.step.label), ["a", "b", "c"]);
      expect(reporter.outputLines, ["hello"]);
      expect(reporter.closed, isTrue);
    });

    test('skips the rest of the run when a step of a stopRun stage fails', () async {
      PipeRunResult result = await PipeRunner([RecordingReporter()]).run("title", [
        PipeStage("Pre-build", steps: [echoStep("clean", 1), succeedingAction("pub get")]),
        PipeStage("Build", steps: [succeedingAction("iOS")], onFailure: FailurePolicy.continueRun),
      ]);

      expect(result.hasFailures, isTrue);
      expect(statuses(result), {"clean": StepStatus.failed, "pub get": StepStatus.skipped, "iOS": StepStatus.skipped});
      expect(result.steps.first.error!.message, "exited with code 1");
    });

    test('runs the rest of the run when a step of a continueRun stage fails', () async {
      PipeRunResult result = await PipeRunner([RecordingReporter()]).run("title", [
        PipeStage("Build", steps: [failingAction("iOS"), succeedingAction("Android")], onFailure: FailurePolicy.continueRun),
        PipeStage("Post-build", steps: [succeedingAction("post")]),
      ]);

      expect(result.failedSteps.map((StepState s) => s.step.label), ["iOS"]);
      expect(statuses(result), {"iOS": StepStatus.failed, "Android": StepStatus.succeeded, "post": StepStatus.succeeded});
    });

    test('turns an exception thrown by a step into a failure', () async {
      RecordingReporter reporter = RecordingReporter();
      PipeRunResult result = await PipeRunner([reporter]).run("title", [
        PipeStage("Stage", steps: [ActionStep("throws", (StepContext context) async => throw StateError("boom"))]),
      ]);

      expect(result.steps.single.status, StepStatus.failed);
      expect(result.steps.single.error!.message, contains("boom"));
      expect(reporter.events.whereType<StepLogged>().single.line, contains("boom"));
    });

    test('fails a command step that cannot be started', () async {
      PipeRunResult result = await PipeRunner([RecordingReporter()]).run("title", [
        PipeStage(
          "Stage",
          steps: [CommandStep("missing", executable: "build_pipe_missing_executable", arguments: [])],
        ),
      ]);

      expect(result.steps.single.status, StepStatus.failed);
      expect(result.steps.single.error!.message, contains("Could not start"));
    });

    test('redacts the command, its output, and the result given to the step', () async {
      RecordingReporter reporter = RecordingReporter();
      List<String> resultOutput = [];
      PipeRunResult result = await PipeRunner([reporter]).run("title", [
        PipeStage(
          "Stage",
          steps: [
            echoStep("command", 0, ["key is secret-key"], ["secret-key", ""]),
            ActionStep("action", (StepContext context) async {
              (CommandResult?, CommandError?) outcome = await context.runCommand(
                Platform.resolvedExecutable,
                ["test/sample/echo_and_exit.dart", "0", "err:id is secret-id"],
                redactions: ["secret-id"],
              );
              resultOutput = outcome.$1!.output;
              return null;
            }),
          ],
        ),
      ]);

      expect(result.hasFailures, isFalse);
      expect(reporter.commandLines.first, endsWith(' 0 "key is REDACTED"'));
      expect(reporter.outputLines, ["key is REDACTED", "id is REDACTED"]);
      expect(resultOutput, ["id is REDACTED"]);
      expect(result.steps.first.recentOutput, ["key is REDACTED"]);
    });

    test('keeps the warnings of a step that still succeeds', () async {
      RecordingReporter reporter = RecordingReporter();
      PipeRunResult result = await PipeRunner([reporter]).run("title", [
        PipeStage(
          "Stage",
          steps: [
            ActionStep("warns", (StepContext context) async {
              context.status("working");
              context.warn("careful");
              return null;
            }),
          ],
        ),
      ]);

      expect(result.steps.single.status, StepStatus.succeeded);
      expect(result.steps.single.warnings, ["careful"]);
      expect(result.warningCount, 1);
      expect(reporter.events.whereType<StepStatusChanged>().single.text, "working");
    });
  });
}
