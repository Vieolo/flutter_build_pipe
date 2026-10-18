import 'dart:io';

import 'package:build_pipe/dx/cli_help.dart';
import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_runner.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:build_pipe/utils/builder.utils.dart';
import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:build_pipe/utils/validation.utils.dart';
import 'package:build_pipe/utils/xcode.utils.dart';

/// Main entry point of the `dart run build_pipe:build` command
void main(List<String> args) async {
  // Handling the build command's --help flag
  handleCommandHelpFlag(args, HelpCommand.build);

  // Reading the config
  (BPConfig?, List<BPConfigValidationError>) configAndErrors = await BPConfig.readPubspec(args);
  // Printing the errors that were found while parsing the config
  // If the error are fatal the config will be null
  if (configAndErrors.$2.isNotEmpty) {
    for (var error in configAndErrors.$2) {
      error.print();
    }
  }
  BPConfig? config = configAndErrors.$1;
  if (config == null) {
    exit(1);
  }

  if (config.buildPlatforms.isEmpty) {
    Console.logError("No target platforms were detected for build. Please add your target platforms to pubspec");
    exit(1);
  }

  bool hasPreBuildCommand = config.preBuildCommand != null && config.preBuildCommand!.isNotEmpty;
  bool hasPostBuildCommand = config.postBuildCommand != null && config.postBuildCommand!.isNotEmpty;

  List<PipeStage> stages = [
    // Nothing should be built when a pre-build step fails
    PipeStage(
      "Pre-build",
      steps: [
        if (config.needXCodeDerivedCleaning) XCodeUtils.deleteDerivedDataStep(config),
        if (config.cleanFlutter) CommandStep("flutter clean", executable: "flutter", arguments: ["clean"]),
        if (config.cleanFlutter) CommandStep("flutter pub get", executable: "flutter", arguments: ["pub", "get"]),
        if (hasPreBuildCommand) CommandStep.fromString("Pre-build command", config.preBuildCommand!),
      ],
    ),
    // The platforms are independent, so a failed build should not stop the others
    PipeStage(
      "Build",
      steps: PipeBuilder.buildSteps(config),
      onFailure: FailurePolicy.continueRun,
    ),
    // The post-build command runs after all platforms have been built, successfully or not
    PipeStage(
      "Post-build",
      steps: [
        if (hasPostBuildCommand) CommandStep.fromString("Post-build command", config.postBuildCommand!),
      ],
    ),
  ];

  PipeRunResult result = await PipeRunner.runWithConfig(config, command: "build", stages: stages);
  if (result.hasFailures) {
    exit(1);
  }
}
