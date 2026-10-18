// Runs the checks of build_pipe in a fixed order, for AI agents and humans alike.
//
// Usage:
//   dart run agent.dart            # every check
//   dart run agent.dart analyze    # only some checks: format, analyze, test
//
// Each check prints PASS or FAIL. The output of a check is shown only when it fails.
// The exit code is 1 when any check has failed.

import 'dart:io';

/// The arguments given to `dart` for each check
const Map<String, List<String>> checks = {
  // The code is formatted with a page width of 200
  "format": ["format", "--page-width=200", "--output=none", "--set-exit-if-changed", "lib", "bin", "test", "agent.dart"],
  "analyze": ["analyze", "--fatal-infos"],
  "test": ["test", "--reporter=expanded"],
};

Future<void> main(List<String> args) async {
  List<String> selected = args.isEmpty ? checks.keys.toList() : args;
  List<String> unknown = selected.where((String name) => !checks.containsKey(name)).toList();
  if (unknown.isNotEmpty) {
    stdout.writeln("Unknown checks: ${unknown.join(", ")}. Available: ${checks.keys.join(", ")}");
    exitCode = 2;
    return;
  }

  if (!await run("pub get", ["pub", "get"])) {
    exitCode = 1;
    return;
  }

  bool passed = true;
  for (String name in selected) {
    // Every check runs, even after a failure, so that one run shows all the problems
    if (!await run(name, checks[name]!)) {
      passed = false;
    }
  }
  exitCode = passed ? 0 : 1;
}

/// Runs `dart` with the [arguments] in the root of the project, and prints whether it has passed
Future<bool> run(String name, List<String> arguments) async {
  // The same dart that runs this script, so that the checks use the same SDK
  String dart = Platform.resolvedExecutable;
  String root = File.fromUri(Platform.script).parent.path;

  ProcessResult result = await Process.run(dart, arguments, workingDirectory: root);
  bool passed = result.exitCode == 0;
  stdout.writeln("${passed ? "PASS" : "FAIL"}  $name  (dart ${arguments.join(" ")})");
  if (!passed) {
    stdout.writeln(result.stdout);
    stderr.writeln(result.stderr);
  }
  return passed;
}
