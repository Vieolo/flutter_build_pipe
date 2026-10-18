import 'dart:io';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_runner.dart';
import 'package:build_pipe/utils/plan.utils.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Keeps the lines printed by the commands, along with the step that printed them
class OutputRecorder implements PipeReporter {
  final List<String> lines = [];

  @override
  void onEvent(PipeEvent event) {
    if (event is CommandOutput) lines.add(event.line);
  }

  @override
  Future<void> close() async {}
}

/// A command for the config of a test: a hook printing env variables, or a build printing a line
String printEnv(String tag, [List<String> names = const []]) => "'${Platform.resolvedExecutable} test/sample/print_env.dart $tag ${names.join(" ")}'";
String buildWith(int exitCode, String line) => "'${Platform.resolvedExecutable} test/sample/echo_and_exit.dart $exitCode $line'";

/// Runs `build_pipe:build` on the given workflow, returning the result and the lines printed by the commands
Future<(PipeRunResult, List<String>)> runBuild(String workflow) async {
  BPConfig config = BPConfig.fromMap(loadYaml(workflow) as YamlMap, [], "1.2.0", "12", workflowName: "release").$1!;
  OutputRecorder recorder = OutputRecorder();
  PipeRunResult result = await PipeRunner([recorder]).run(const PipeRunInfo(command: "build", workflow: "release", version: "1.2.0+12"), PipePlan.build(config));
  return (result, recorder.lines);
}

Map<String, StepStatus> statusesByNumber(PipeRunResult result) => {for (StepState s in result.allSteps) "${s.number} ${s.step.label}": s.status};

void main() {
  test('runs the hooks around the platforms, in the platform order, with the env variables', () async {
    (PipeRunResult, List<String>) run = await runBuild('''
clean_flutter: false
pre_platform_run:
  build: ${printEnv("pre_platform_run", ["BUILD_PIPE_COMMAND", "BUILD_PIPE_WORKFLOW", "BUILD_PIPE_VERSION"])}
post_platform_run:
  build:
    on_success: ${printEnv("on_success")}
    finally: ${printEnv("finally", ["BUILD_PIPE_STATUS", "BUILD_PIPE_SUCCEEDED_PLATFORMS", "BUILD_PIPE_FAILED_PLATFORMS", "BUILD_PIPE_SKIPPED_PLATFORMS"])}
platforms:
  linux:
    build:
      build_command: ${buildWith(0, "linux_built")}
  ios:
    build:
      pre_command: ${printEnv("ios_pre", ["BUILD_PIPE_PLATFORM"])}
      build_command: ${buildWith(1, "ios_failed")}
      post_command:
        on_success: ${printEnv("ios_on_success")}
        finally: ${printEnv("ios_finally", ["BUILD_PIPE_STATUS"])}
  android:
    build:
      build_command: ${buildWith(0, "android_built")}
''');

    expect(statusesByNumber(run.$1), {
      "1 Pre-platform run": StepStatus.succeeded,
      "2 Android": StepStatus.succeeded,
      "3 iOS": StepStatus.failed,
      "3.1 Pre command": StepStatus.succeeded,
      "3.2 Build": StepStatus.failed,
      "3.3 On success": StepStatus.skipped,
      "3.4 Finally": StepStatus.succeeded,
      "4 Linux": StepStatus.succeeded,
      "5 On success": StepStatus.skipped,
      "6 Finally": StepStatus.succeeded,
    });
    expect(run.$2, [
      "pre_platform_run BUILD_PIPE_COMMAND=build",
      "pre_platform_run BUILD_PIPE_WORKFLOW=release",
      "pre_platform_run BUILD_PIPE_VERSION=1.2.0+12",
      "android_built",
      "ios_pre BUILD_PIPE_PLATFORM=ios",
      "ios_failed",
      "ios_finally BUILD_PIPE_STATUS=failed",
      "linux_built",
      "finally BUILD_PIPE_STATUS=failed",
      "finally BUILD_PIPE_SUCCEEDED_PLATFORMS=android,linux",
      "finally BUILD_PIPE_FAILED_PLATFORMS=ios",
      "finally BUILD_PIPE_SKIPPED_PLATFORMS=",
    ]);
    expect(run.$1.hasFailures, isTrue);
  });

  test('runs the on_success hooks when nothing has failed', () async {
    (PipeRunResult, List<String>) run = await runBuild('''
clean_flutter: false
post_platform_run:
  build:
    on_success: ${printEnv("on_success", ["BUILD_PIPE_SUCCEEDED_PLATFORMS"])}
    finally: ${printEnv("finally", ["BUILD_PIPE_STATUS"])}
platforms:
  web:
    build:
      build_command: ${buildWith(0, "web_built")}
      add_version_query_param: false
      post_command:
        on_success: ${printEnv("web_on_success", ["BUILD_PIPE_PLATFORM"])}
''');

    expect(run.$1.hasFailures, isFalse);
    expect(run.$2, [
      "web_built",
      "web_on_success BUILD_PIPE_PLATFORM=web",
      "on_success BUILD_PIPE_SUCCEEDED_PLATFORMS=web",
      "finally BUILD_PIPE_STATUS=succeeded",
    ]);
  });

  test('runs no platform when pre_platform_run fails, but still runs its finally', () async {
    (PipeRunResult, List<String>) run = await runBuild('''
clean_flutter: false
pre_platform_run:
  build: ${buildWith(3, "pre_failed")}
post_platform_run:
  build:
    on_success: ${printEnv("on_success")}
    finally: ${printEnv("finally", ["BUILD_PIPE_STATUS", "BUILD_PIPE_SKIPPED_PLATFORMS"])}
platforms:
  android:
    build:
      build_command: ${buildWith(0, "android_built")}
      post_command:
        finally: ${printEnv("android_finally")}
  web:
    build:
      build_command: ${buildWith(0, "web_built")}
      add_version_query_param: false
''');

    expect(statusesByNumber(run.$1), {
      "1 Pre-platform run": StepStatus.failed,
      "2 Android": StepStatus.skipped,
      "2.1 Build": StepStatus.skipped,
      "2.2 Finally": StepStatus.skipped,
      "3 Web": StepStatus.skipped,
      "4 On success": StepStatus.skipped,
      "5 Finally": StepStatus.succeeded,
    });
    expect(run.$2, [
      "pre_failed",
      "finally BUILD_PIPE_STATUS=failed",
      "finally BUILD_PIPE_SKIPPED_PLATFORMS=android,web",
    ]);
  });
}
