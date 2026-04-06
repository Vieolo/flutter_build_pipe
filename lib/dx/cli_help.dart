import 'dart:io';

import 'package:args/args.dart';
import 'package:build_pipe/utils/console.utils.dart';

enum HelpCommand { build, publish }

/// Handles the print of the content of the `--help` flag
///
/// Once printed, the program will exit with a `0` exit code
void handleHelpFlag(List<String> args, HelpCommand command) {
  if (args.contains("--help")) {
    var options = ArgParser();
    options
      ..addOption(
        "workflow",
        mandatory: false,
        defaultsTo: "default",
        help: "Select the workflow to be run. If no workflow is provided, the `default` workflow will be used.",
      )
      ..addOption(
        "override-target-platforms",
        mandatory: false,
        help:
            "Running only one or multiple target platforms of a workflow, overriding platforms defined for the workflow in the pubspec. If multiple target platforms is required, separate them by a comma (e.g., ios, android)",
      );

    var flags = ArgParser();
    flags.addFlag("help", help: "Provides additional explanation for the command", negatable: false);

    if (command == HelpCommand.build) {
      Console.logInfo("\nBuilds the Flutter app for all of the target platforms of the selected workflow\n");
    } else {
      Console.logInfo("\nPublishes the built artifacts of Flutter app for all of the target platforms of the selected workflow\n");
    }

    Console.logWarning("DESCRIPTION");
    if (command == HelpCommand.build) {
      print(
        "  Runs the build commands of all target platforms of a workflow. "
        "The workflow can be selected via the `--workflow` arg, else the `default` workflow is used. "
        "The options, flags, and args defined blow will be processed by the command directly. "
        "Any unknown and extra arg provided, will be piped downstream to the platform-specific build command of Flutter.",
      );
    } else {
      print(
        "  Publishes the built artifacts of all target platforms of a workflow. "
        "The workflow can be selected via the `--workflow` arg, else the `default` workflow is used. ",
      );
    }

    Console.logWarning("\nUSAGE");
    if (command == HelpCommand.build) {
      print("  dart run build_pipe:build [KNOWN_ARGS] [DOWNSTREAM_ARGS]\n");
    } else {
      print("  dart run build_pipe:publish [ARGS]\n");
    }

    Console.logWarning("\nEXAMPLE");
    if (command == HelpCommand.build) {
      print("  dart run build_pipe:build --workflow=local_build\n");
    } else {
      print("  dart run build_pipe:publish --workflow=local_publish\n");
    }

    Console.logWarning("OPTIONS");
    print(options.usage);

    Console.logWarning("\nFLAGS");
    print(flags.usage);
    exit(0);
  }
}
