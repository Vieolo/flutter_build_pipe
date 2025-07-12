import 'package:yaml/yaml.dart';

enum TargetPlatform { web, ios, android, macos, windows, linux }

class BuildConfigPlatform {
  TargetPlatform platform;
  String buildCommand;

  BuildConfigPlatform({required this.platform, required this.buildCommand});

  static BuildConfigPlatform? fromMap(YamlMap data, TargetPlatform platform) {
    if (!data.containsKey("build_command") || data["build_command"].toString().isEmpty) {
      return null;
    }
    return BuildConfigPlatform(
      platform: platform,
      buildCommand: data["build_command"],
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

  BuildConfig({
    this.android,
    this.ios,
    this.linux,
    this.macos,
    this.web,
    this.windows,
    this.xcodeDerivedKey,
  });

  factory BuildConfig.fromMap(YamlMap data) {
    return BuildConfig(
      android: data.containsKey("android") ? BuildConfigPlatform.fromMap(data["android"], TargetPlatform.android) : null,
      ios: data.containsKey("ios") ? BuildConfigPlatform.fromMap(data["ios"], TargetPlatform.ios) : null,
      macos: data.containsKey("macos") ? BuildConfigPlatform.fromMap(data["macos"], TargetPlatform.macos) : null,
      linux: data.containsKey("linux") ? BuildConfigPlatform.fromMap(data["linux"], TargetPlatform.linux) : null,
      windows: data.containsKey("windows") ? BuildConfigPlatform.fromMap(data["windows"], TargetPlatform.windows) : null,
      web: data.containsKey("web") ? BuildConfigPlatform.fromMap(data["web"], TargetPlatform.web) : null,
    );
  }
}
