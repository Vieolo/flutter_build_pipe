import 'dart:io';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/dx/cli_help.dart';
import 'package:build_pipe/dx/command_setup.dart';
import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_runner.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:build_pipe/utils/console.utils.dart';

/// https://help.apple.com/asc/appsaltool/#/apdATD1E53-D1E1A1303-D1E53A1126
/// Main entry point of the `dart run build_pipe:publish` command
void main(List<String> args) async {
  BPConfig? config = await loadCommandConfig(args, HelpCommand.publish);
  if (config == null) {
    exit(1);
  }

  if (config.publishPlatforms.isEmpty) {
    Console.logError("No target platforms were detected for publish. Please add your target platforms to pubspec");
    exit(1);
  }

  List<PipeStage> stages = [
    // The stores are independent, so a failed upload should not stop the others
    PipeStage(
      "Publish",
      onFailure: FailurePolicy.continueRun,
      steps: [
        if (config.ios?.iosConfig?.publishConfig != null) config.ios!.iosConfig!.publishConfig!.uploadToIOSStep(config),
        if (config.android?.androidConfig?.publishConfig != null) config.android!.androidConfig!.publishConfig!.uploadToPlayStoreStep(config),
      ],
    ),
  ];

  PipeRunResult result = await PipeRunner.runWithConfig(config, command: "publish", stages: stages);
  if (result.hasFailures) {
    exit(1);
  }
}
