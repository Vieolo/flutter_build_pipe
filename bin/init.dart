import 'dart:io';

import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/dx/cli_help.dart';
import 'package:build_pipe/dx/init_command.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:path/path.dart' as p;

/// Main entry point of the `dart run build_pipe:init` command
void main(List<String> args) async {
  handleCommandHelpFlag(args, HelpCommand.init);

  List<String> unknown = args.where((String arg) => arg != "--print").toList();
  if (unknown.isNotEmpty) {
    Console.logError("Unknown option: ${unknown.join(" ")}. Use --help to see the options");
    exit(1);
  }

  bool printOnly = args.contains("--print");
  (InitResult?, String?) result = await InitCommand.run(Directory.current.path, write: !printOnly);
  if (result.$2 != null) {
    Console.logError(result.$2!);
    exit(1);
  }

  InitResult init = result.$1!;
  if (printOnly) {
    // Only the config, so that it can be redirected to a file
    stdout.write(init.scaffold);
    return;
  }

  Console.logSuccess("√ Added the build_pipe config to pubspec.yaml");
  if (init.platforms.isEmpty) {
    Console.logWarning("No platform folders were found, so all the platforms are commented out. Uncomment the ones you build");
  } else {
    print("Platforms found in the project: ${init.platforms.map((TargetPlatform p) => p.name).join(", ")}");
  }
  print("The optional fields are commented out. Uncomment the ones you need");

  File gitignore = File(p.join(Directory.current.path, ".gitignore"));
  if (await gitignore.exists() && !(await gitignore.readAsString()).contains(".flutter_build_pipe")) {
    print("Add .flutter_build_pipe/ to your .gitignore, since the log files are written there");
  }
  print("\nRun the build with: dart run build_pipe:build");
}
