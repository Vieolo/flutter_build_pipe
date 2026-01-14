import 'dart:io';

import 'package:build_pipe/utils/builder.utils.dart';
import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:build_pipe/utils/process.utils.dart';
import 'package:build_pipe/utils/xcode.utils.dart';

/// Main entry point of the `dart run build_pipe:build` command
void main(List<String> args) async {
  BPConfig config = await BPConfig.readPubspec(args);

  if (config.buildPlatforms.isEmpty) {
    Console.logError("No target platforms were detected for build. Please add your target platforms to pubspec");
    exit(1);
  }

  Console.logInfo("\nStarting the build process...\n");
  print("The following target platforms are detected:");
  for (var i = 0; i < config.buildPlatforms.length; i++) {
    String prefix = "├──";
    if (i == config.buildPlatforms.length - 1) {
      prefix = "└──";
    }
    print("$prefix ${config.buildPlatforms[i].name}${i == config.buildPlatforms.length - 1 ? "\n" : ""}");
  }

  if (config.cleanFlutter || config.needXCodeDerivedCleaning) {
    Console.logInfo("Pre-build cleanups...");
  }

  if (config.needXCodeDerivedCleaning) {
    String? xcodePath = Platform.environment[config.xcodeDerivedKey!];
    if (xcodePath == null || xcodePath.isEmpty) {
      Console.logError(
        "└── ${config.xcodeDerivedKey} is either not a valid environmental variable or has an empty value!",
      );
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
      startMessage: "└── Cleaning flutter existing builds...",
      clearStartMessage: true,
      successMessage: "└── √ Flutter cleaned",
      errorMessage: "└── X There was an error while cleaning the Flutter build",
    );

    await ProcessHelper.runCommandUsingConfig(
      executable: "flutter",
      arguments: ["pub", "get"],
      config: config,
      startMessage: "└── Getting pub packages...",
      clearStartMessage: true,
      successMessage: "└── √ Flutter pub packages synced\n",
      errorMessage: "└── X There was an error while getting pub packages",
    );
  }

  if (config.preBuildCommand != null && config.preBuildCommand!.isNotEmpty) {
    await ProcessHelper.runCommandUsingConfig(
      executable: config.preBuildCommand!.split(" ")[0],
      arguments: config.preBuildCommand!.split(" ").sublist(1),
      config: config,
      startMessage: "\nRunning pre-build command...",
      clearStartMessage: true,
      successMessage: "√ pre-build command is completed",
      errorMessage: "X pre-build command has failed",
    );
  }

  Console.logInfo("Building the app...");
  await PipeBuilder.buildAll(config);

  if (config.postBuildCommand != null && config.postBuildCommand!.isNotEmpty) {
    await ProcessHelper.runCommandUsingConfig(
      executable: config.postBuildCommand!.split(" ")[0],
      arguments: config.postBuildCommand!.split(" ").sublist(1),
      config: config,
      startMessage: "\nRunning post-build command...",
      clearStartMessage: true,
      successMessage: "√ post-build command is completed",
      errorMessage: "X post-build command has failed",
    );
  }

  print("\nBuild is completed");
  if (config.generateLog) {
    print("log is generated at: ${config.logFile}\n");
  }
}
