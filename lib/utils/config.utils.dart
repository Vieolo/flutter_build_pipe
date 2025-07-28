import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

enum TargetPlatform { web, ios, android, macos, windows, linux }

class BuildConfigPlatform {
  // General
  TargetPlatform platform;
  String buildCommand;

  // Web specific
  bool? addVersionQueryParam;

  BuildConfigPlatform({required this.platform, required this.buildCommand, this.addVersionQueryParam});

  static BuildConfigPlatform? fromMap(YamlMap data, TargetPlatform platform) {
    if (!data.containsKey("build_command") || data["build_command"].toString().isEmpty) {
      return null;
    }
    return BuildConfigPlatform(
      platform: platform,
      buildCommand: data["build_command"],
      addVersionQueryParam: platform == TargetPlatform.web ? (data['add_version_query_param'] ?? true) : null,
    );
  }
}

class BuildConfig {
  BuildConfigPlatform? web;
  BuildConfigPlatform? ios;
  BuildConfigPlatform? android;
  BuildConfigPlatform? macos;
  BuildConfigPlatform? windows;
  BuildConfigPlatform? linux;
  String? xcodeDerivedKey;
  bool cleanFlutter;
  bool printstdout;
  DateTime timestamp;
  String version;
  bool generateLog;
  String? postBuildCommand;

  BuildConfig({
    this.android,
    this.ios,
    this.linux,
    this.macos,
    this.web,
    this.windows,
    this.xcodeDerivedKey,
    this.postBuildCommand,
    required this.cleanFlutter,
    required this.printstdout,
    required this.timestamp,
    required this.version,
    required this.generateLog,
  });

  factory BuildConfig.fromMap(YamlMap data, String version) {
    YamlMap platforms = data["platforms"] ?? {};
    return BuildConfig(
      android: platforms.containsKey("android") ? BuildConfigPlatform.fromMap(platforms["android"], TargetPlatform.android) : null,
      ios: platforms.containsKey("ios") ? BuildConfigPlatform.fromMap(platforms["ios"], TargetPlatform.ios) : null,
      macos: platforms.containsKey("macos") ? BuildConfigPlatform.fromMap(platforms["macos"], TargetPlatform.macos) : null,
      linux: platforms.containsKey("linux") ? BuildConfigPlatform.fromMap(platforms["linux"], TargetPlatform.linux) : null,
      windows: platforms.containsKey("windows") ? BuildConfigPlatform.fromMap(platforms["windows"], TargetPlatform.windows) : null,
      web: platforms.containsKey("web") ? BuildConfigPlatform.fromMap(platforms["web"], TargetPlatform.web) : null,
      xcodeDerivedKey: data["xcode_derived_data_path_env_key"],
      cleanFlutter: data["clean_flutter"] ?? true,
      generateLog: data["generate_log"] ?? true,
      printstdout: data["print_stdout"] ?? false,
      postBuildCommand: data["post_build_command"],
      timestamp: DateTime.now(),
      version: version,
    );
  }

  String get logFile => generateLog ? p.join(Directory.current.path, ".flutter_build_pipe", "logs", version, "${timestamp.toIso8601String()}.log") : "";
  bool get needXCodeDerivedCleaning => (ios != null || macos != null) && xcodeDerivedKey != null && xcodeDerivedKey!.isNotEmpty;
  List<TargetPlatform> get platforms => [
    if (ios != null) TargetPlatform.ios,
    if (android != null) TargetPlatform.android,
    if (macos != null) TargetPlatform.macos,
    if (linux != null) TargetPlatform.linux,
    if (windows != null) TargetPlatform.windows,
    if (web != null) TargetPlatform.web,
  ];
}
