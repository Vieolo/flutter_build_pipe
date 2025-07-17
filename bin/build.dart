import 'dart:io';

import 'package:build_pipe/utils/builder.utils.dart';
import 'package:build_pipe/utils/config.utils.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:build_pipe/utils/process.utils.dart';
import 'package:build_pipe/utils/xcode.utils.dart';
import 'package:yaml/yaml.dart' as yaml;

void main(List<String> args) async {
  final rawPubspecFile = File('pubspec.yaml');
  if (!(await rawPubspecFile.exists())) {
    Console.logError("pubspec.yaml file could not be found!");
    return;
  }

  final pubspec = yaml.loadYaml(await rawPubspecFile.readAsString());
  if (!(pubspec as yaml.YamlMap).containsKey("build_pipe")) {
    Console.logError("please add the build_pipe configuration to your pubspec file!");
    return;
  }

  final config = BuildConfig.fromMap(pubspec["build_pipe"], pubspec["version"].split("+")[0]);
  if (config.platforms.isEmpty) {
    Console.logError("No target platforms were detected. Please add your target platforms to pubspec");
    return;
  }

  Console.logInfo("\nStarting the build process...\n");
  print("The following target platforms are detected:");
  print("${config.platforms.map((z) => z.name).join(", ")}\n");

  if (config.xcodeDerivedKey != null && config.xcodeDerivedKey!.isNotEmpty && config.platforms.any((z) => z == TargetPlatform.ios || z == TargetPlatform.macos)) {
    String? xcodePath = Platform.environment[config.xcodeDerivedKey!];
    if (xcodePath == null || xcodePath.isEmpty) {
      Console.logError("${config.xcodeDerivedKey} is either not a valid environmental variable or has an empty value!");
    } else {
      bool deleted = await XCodeUtils.deleteDerivedData(config, xcodePath);
      if (!deleted) {
        exit(1);
      }
    }
  }

  if (config.cleanFlutter) {
    await ProcessHelper.runCommandUsingConfig(
      executable: "flutter",
      arguments: ["clean"],
      config: config,
      startMessage: "Cleaning flutter existing builds...",
      successMessage: "√ Flutter cleaned",
      errorMessage: "X There was an error while cleaning the Flutter build",
    );

    await ProcessHelper.runCommandUsingConfig(
      executable: "flutter",
      arguments: ["pub", "get"],
      config: config,
      startMessage: "Getting pub packages",
      successMessage: "√ Flutter pub packages synced\n",
      errorMessage: "X There was an error while getting pub packages",
    );
  }

  await PipeBuilder.buildAll(config);

  if (config.postBuildCommand != null && config.postBuildCommand!.isNotEmpty) {
    await ProcessHelper.runCommandUsingConfig(
      executable: config.postBuildCommand!.split(" ")[0],
      arguments: config.postBuildCommand!.split(" ").sublist(1),
      config: config,
      startMessage: "\nRunning post-build command...",
      successMessage: "√ post-build command is completed",
      errorMessage: "X post-build command has failed",
    );
  }

  print("\nBuild is completed");
  if (config.generateLog) {
    print("log is generated at: ${config.logFile}\n");
  }
}
