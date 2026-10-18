import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/config/hook_config.dart';
import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:build_pipe/utils/builder.utils.dart';
import 'package:build_pipe/utils/process.utils.dart';
import 'package:build_pipe/utils/xcode.utils.dart';

/// Lays out the stages and the steps of the build and publish commands
///
/// Both commands have the same layout:
/// 1. A stage before the platforms: the preparations of the command, then `pre_platform_run`. When any
///    of them fails, no platform runs
/// 2. A stage with a step per platform, in [BPConfig.platformOrder]. The platforms are independent, so a
///    failed platform does not stop the others. A platform with hooks or extra steps is a group of
///    `pre_command`, the build or the upload, the extra steps, `post_command.on_success`, and `post_command.finally`
/// 3. A stage after the platforms: `post_platform_run.on_success`, which runs only when nothing has
///    failed, and `post_platform_run.finally`, which runs in any case
class PipePlan {
  /// The user-facing names of the platforms
  static const Map<TargetPlatform, String> platformNames = {
    TargetPlatform.android: "Android",
    TargetPlatform.ios: "iOS",
    TargetPlatform.macos: "macOS",
    TargetPlatform.windows: "Windows",
    TargetPlatform.linux: "Linux",
    TargetPlatform.web: "Web",
  };

  /// The stages of `build_pipe:build`
  static List<PipeStage> build(BPConfig config) {
    _HookEnvironment environment = _HookEnvironment(config, "build");

    List<PipeStep> platformSteps = [];
    for (TargetPlatform platform in config.buildPlatforms) {
      PlatformConfig platformConfig = config.platformConfig(platform)!;
      // Safety check in case an empty build command is passed
      // and the lack of build command is not caught by the config parser
      if (platformConfig.buildCommand.isEmpty) continue;

      PipeStep step = _platformStep(
        label: platformNames[platform]!,
        mainLabel: "Build",
        main: (String label) => PipeBuilder.buildCommandStep(config, platformConfig, label),
        extraSteps: PipeBuilder.extraBuildSteps(config, platform),
        hooks: platformConfig.buildHooks,
        platform: platform,
        environment: environment,
      );
      environment.platformSteps[step] = platform;
      platformSteps.add(step);
    }

    return [
      PipeStage(
        "Pre-build",
        steps: [
          if (config.needXCodeDerivedCleaning) XCodeUtils.deleteDerivedDataStep(config),
          if (config.cleanFlutter) CommandStep("flutter clean", executable: "flutter", arguments: ["clean"]),
          if (config.cleanFlutter) CommandStep("flutter pub get", executable: "flutter", arguments: ["pub", "get"]),
          if (config.buildHooks.pre != null) _hookStep("Pre-platform run", config.buildHooks.pre!, environment.forPrePlatformRun),
        ],
      ),
      PipeStage("Build", steps: platformSteps, onFailure: FailurePolicy.continueRun),
      PipeStage("Post-build", steps: _postPlatformRunSteps(config.buildHooks, environment)),
    ];
  }

  /// The stages of `build_pipe:publish`
  static List<PipeStage> publish(BPConfig config) {
    _HookEnvironment environment = _HookEnvironment(config, "publish");

    List<PipeStep> platformSteps = [];
    for (TargetPlatform platform in config.publishPlatforms) {
      PlatformConfig platformConfig = config.platformConfig(platform)!;
      (String, PipeStep Function(String label))? upload = switch (platform) {
        TargetPlatform.android => (
          "Android - Play Store",
          (String label) => platformConfig.androidConfig!.publishConfig!.uploadToPlayStoreStep(config, label: label),
        ),
        TargetPlatform.ios => (
          "iOS - App Store",
          (String label) => platformConfig.iosConfig!.publishConfig!.uploadToIOSStep(config, label: label),
        ),
        // Only the stores of iOS and Android are supported at the moment
        TargetPlatform.macos || TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.web => null,
      };
      if (upload == null) continue;

      PipeStep step = _platformStep(
        label: upload.$1,
        mainLabel: "Upload",
        main: upload.$2,
        extraSteps: [],
        hooks: platformConfig.publishHooks,
        platform: platform,
        environment: environment,
      );
      environment.platformSteps[step] = platform;
      platformSteps.add(step);
    }

    return [
      PipeStage(
        "Pre-publish",
        steps: [
          if (config.publishHooks.pre != null) _hookStep("Pre-platform run", config.publishHooks.pre!, environment.forPrePlatformRun),
        ],
      ),
      PipeStage("Publish", steps: platformSteps, onFailure: FailurePolicy.continueRun),
      PipeStage("Post-publish", steps: _postPlatformRunSteps(config.publishHooks, environment)),
    ];
  }

  /// The step of a platform: its [main] step alone, or a group when the platform has hooks or extra steps
  ///
  /// The [main] step is labelled with the [label] when it is alone, and with the [mainLabel] in a group
  static PipeStep _platformStep({
    required String label,
    required String mainLabel,
    required PipeStep Function(String label) main,
    required List<PipeStep> extraSteps,
    required HookCommands hooks,
    required TargetPlatform platform,
    required _HookEnvironment environment,
  }) {
    if (hooks.isEmpty && extraSteps.isEmpty) return main(label);

    Map<String, String> platformEnvironment(StepContext context) => environment.forPlatform(context, platform, isFinally: false);
    Map<String, String> finallyEnvironment(StepContext context) => environment.forPlatform(context, platform, isFinally: true);
    return StepGroup(label, [
      if (hooks.pre != null) _hookStep("Pre command", hooks.pre!, platformEnvironment),
      main(mainLabel),
      ...extraSteps,
      if (hooks.onSuccess != null) _hookStep("On success", hooks.onSuccess!, platformEnvironment),
      if (hooks.finallyCommand != null) _hookStep("Finally", hooks.finallyCommand!, finallyEnvironment, runIf: RunCondition.always),
    ]);
  }

  /// The `on_success` and `finally` of `post_platform_run`
  static List<PipeStep> _postPlatformRunSteps(HookCommands hooks, _HookEnvironment environment) {
    return [
      if (hooks.onSuccess != null)
        _hookStep(
          "On success",
          hooks.onSuccess!,
          (StepContext context) => environment.forPostPlatformRun(context, isFinally: false),
          runIf: RunCondition.nothingFailed,
        ),
      if (hooks.finallyCommand != null)
        _hookStep(
          "Finally",
          hooks.finallyCommand!,
          (StepContext context) => environment.forPostPlatformRun(context, isFinally: true),
          runIf: RunCondition.always,
        ),
    ];
  }

  /// The step running a hook, with the env variables describing the run
  static PipeStep _hookStep(
    String label,
    String command,
    Map<String, String> Function(StepContext context) environment, {
    RunCondition runIf = RunCondition.notStopped,
  }) {
    return ActionStep(label, (StepContext context) async {
      Map<String, String> env = environment(context);
      context.log("env: ${env.entries.map((MapEntry<String, String> e) => "${e.key}=${e.value}").join(" ")}");
      List<String> parts = ProcessHelper.splitCommand(command);
      return StepError.fromCommand(await context.runCommand(parts.first, parts.skip(1).toList(), environment: env));
    }, runIf: runIf);
  }
}

/// The env variables given to the hooks, describing the run at the moment the hook runs
class _HookEnvironment {
  final BPConfig config;

  /// The build_pipe command, `build` or `publish`
  final String command;

  /// The step of each platform, to tell which platforms have succeeded
  final Map<PipeStep, TargetPlatform> platformSteps = {};

  _HookEnvironment(this.config, this.command);

  Map<String, String> get _common => {
    "BUILD_PIPE_COMMAND": command,
    "BUILD_PIPE_WORKFLOW": config.workflowName,
    "BUILD_PIPE_VERSION": "${config.version}+${config.buildVersion}",
  };

  /// For the hooks of a platform. Its `finally` also gets whether any step of the platform has failed
  Map<String, String> forPlatform(StepContext context, TargetPlatform platform, {required bool isFinally}) {
    return {
      ..._common,
      "BUILD_PIPE_PLATFORM": platform.name,
      if (isFinally) "BUILD_PIPE_STATUS": _status(context.state.parent?.children ?? []),
    };
  }

  /// For `pre_platform_run`, which runs before the platforms
  Map<String, String> forPrePlatformRun(StepContext context) => _common;

  /// For `post_platform_run`, which gets the outcome of the platforms. Its `finally` also gets whether
  /// any step of the run has failed
  Map<String, String> forPostPlatformRun(StepContext context, {required bool isFinally}) {
    List<StepState> runSteps = context.runSteps;
    String platformsWith(StepStatus status) => [
      for (StepState step in runSteps)
        if (platformSteps.containsKey(step.step) && step.status == status) platformSteps[step.step]!.name,
    ].join(",");

    return {
      ..._common,
      if (isFinally) "BUILD_PIPE_STATUS": _status(runSteps),
      "BUILD_PIPE_SUCCEEDED_PLATFORMS": platformsWith(StepStatus.succeeded),
      "BUILD_PIPE_FAILED_PLATFORMS": platformsWith(StepStatus.failed),
      "BUILD_PIPE_SKIPPED_PLATFORMS": platformsWith(StepStatus.skipped),
    };
  }

  /// `failed` when any of the [steps] has failed, otherwise `succeeded`
  String _status(List<StepState> steps) => steps.any((StepState step) => step.status == StepStatus.failed) ? "failed" : "succeeded";
}
