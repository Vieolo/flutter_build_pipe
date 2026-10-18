import 'dart:io';

import 'package:build_pipe/dx/cli_help.dart';
import 'package:build_pipe/dx/command_setup.dart';
import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_runner.dart';
import 'package:build_pipe/utils/plan.utils.dart';
import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/utils/console.utils.dart';

/// Main entry point of the `dart run build_pipe:build` command
void main(List<String> args) async {
  BPConfig? config = await loadCommandConfig(args, HelpCommand.build);
  if (config == null) {
    exit(1);
  }

  if (config.buildPlatforms.isEmpty) {
    Console.logError("No target platforms were detected for build. Please add your target platforms to pubspec");
    exit(1);
  }

  PipeRunResult result = await PipeRunner.runWithConfig(config, command: "build", stages: PipePlan.build(config));
  if (result.hasFailures) {
    exit(1);
  }
}
