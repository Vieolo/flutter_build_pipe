import 'dart:io';

import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml;

/// The actual class holding the fields of the config
class BPConfig {
  PlatformConfig? web;
  PlatformConfig? ios;
  PlatformConfig? android;
  PlatformConfig? macos;
  PlatformConfig? windows;
  PlatformConfig? linux;
  String? xcodeDerivedKey;
  bool cleanFlutter;
  bool printstdout;
  DateTime timestamp;
  String version;
  String buildVersion;
  bool generateLog;
  String? preBuildCommand;
  String? postBuildCommand;
  List<String> cmdArgs;

  BPConfig({
    this.android,
    this.ios,
    this.linux,
    this.macos,
    this.web,
    this.windows,
    this.xcodeDerivedKey,
    this.preBuildCommand,
    this.postBuildCommand,
    required this.cleanFlutter,
    required this.printstdout,
    required this.timestamp,
    required this.version,
    required this.generateLog,
    required this.buildVersion,
    required this.cmdArgs,
  });

  /// Parsed the config from the map
  factory BPConfig.fromMap(
    yaml.YamlMap data,
    List<String> args,
    String version,
    String buildVersion,
  ) {
    yaml.YamlMap platforms = data["platforms"] ?? {};
    return BPConfig(
      android: platforms.containsKey("android")
          ? PlatformConfig.fromMap(
              platforms["android"],
              TargetPlatform.android,
            )
          : null,
      ios: platforms.containsKey("ios") ? PlatformConfig.fromMap(platforms["ios"], TargetPlatform.ios) : null,
      macos: platforms.containsKey("macos")
          ? PlatformConfig.fromMap(
              platforms["macos"],
              TargetPlatform.macos,
            )
          : null,
      linux: platforms.containsKey("linux")
          ? PlatformConfig.fromMap(
              platforms["linux"],
              TargetPlatform.linux,
            )
          : null,
      windows: platforms.containsKey("windows")
          ? PlatformConfig.fromMap(
              platforms["windows"],
              TargetPlatform.windows,
            )
          : null,
      web: platforms.containsKey("web") ? PlatformConfig.fromMap(platforms["web"], TargetPlatform.web) : null,
      xcodeDerivedKey: data["xcode_derived_data_path_env_key"],
      cleanFlutter: data["clean_flutter"] ?? true,
      generateLog: data["generate_log"] ?? true,
      printstdout: data["print_stdout"] ?? false,
      preBuildCommand: data["pre_build_command"],
      postBuildCommand: data["post_build_command"],
      timestamp: DateTime.now(),
      version: version,
      buildVersion: buildVersion,
      cmdArgs: args,
    );
  }

  /// Gets the path of the log file, if log generation is not prevented via the config
  String get logFile {
    String fileName = "${timestamp.toIso8601String()}.log";

    // In windows, it seems that, the file name cannot
    // contain `:`
    if (Platform.isWindows) {
      fileName = fileName.replaceAll(":", "_");
    }

    return generateLog
        ? p.join(
            Directory.current.path,
            ".flutter_build_pipe",
            "logs",
            version,
            fileName,
          )
        : "";
  }

  /// Checks if the XCode derived data is provided AND there is a build target for Apple devices
  bool get needXCodeDerivedCleaning => (ios != null || macos != null) && xcodeDerivedKey != null && xcodeDerivedKey!.isNotEmpty;

  /// The list of target platforms provided in the config
  List<TargetPlatform> get platforms => [
    if (ios != null) TargetPlatform.ios,
    if (android != null) TargetPlatform.android,
    if (macos != null) TargetPlatform.macos,
    if (linux != null) TargetPlatform.linux,
    if (windows != null) TargetPlatform.windows,
    if (web != null) TargetPlatform.web,
  ];

  static Future<BPConfig> readPubspec(List<String> args) async {
    final rawPubspecFile = File('pubspec.yaml');
    if (!(await rawPubspecFile.exists())) {
      Console.logError("pubspec.yaml file could not be found!");
      exit(1);
    }

    final pubspec = yaml.loadYaml(await rawPubspecFile.readAsString());
    if (!(pubspec as yaml.YamlMap).containsKey("build_pipe")) {
      Console.logError(
        "please add the build_pipe configuration to your pubspec file!",
      );
      exit(1);
    }

    final config = BPConfig.fromMap(
      pubspec["build_pipe"],
      args,
      pubspec["version"].split("+")[0],
      // just in case the + doesnt exist
      pubspec["version"].split("+").length > 1
          ? pubspec["version"].split("+")[1]
          : "0",
    );

    if (config.platforms.isEmpty) {
      Console.logError(
        "No target platforms were detected. Please add your target platforms to pubspec",
      );
      exit(1);
    }

    return config;
  }
}
