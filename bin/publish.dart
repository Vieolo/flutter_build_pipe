import 'dart:io';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/dx/cli_help.dart';
import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_runner.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:build_pipe/utils/validation.utils.dart';

/// https://help.apple.com/asc/appsaltool/#/apdATD1E53-D1E1A1303-D1E53A1126
/// Main entry point of the `dart run build_pipe:publish` command
void main(List<String> args) async {
  // Handling the publish command's --help flag
  handleCommandHelpFlag(args, HelpCommand.publish);

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
