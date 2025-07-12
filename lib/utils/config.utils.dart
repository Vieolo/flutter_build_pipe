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
  bool cleanFlutter;

  BuildConfig({
    this.android,
    this.ios,
    this.linux,
    this.macos,
    this.web,
    this.windows,
    this.xcodeDerivedKey,
    required this.cleanFlutter,
  });

  factory BuildConfig.fromMap(YamlMap data) {
    YamlMap platforms = data["platforms"] ?? {};
    return BuildConfig(
      android: platforms.containsKey("android") ? BuildConfigPlatform.fromMap(platforms["android"], TargetPlatform.android) : null,
      ios: platforms.containsKey("ios") ? BuildConfigPlatform.fromMap(platforms["ios"], TargetPlatform.ios) : null,
      macos: platforms.containsKey("macos") ? BuildConfigPlatform.fromMap(platforms["macos"], TargetPlatform.macos) : null,
      linux: platforms.containsKey("linux") ? BuildConfigPlatform.fromMap(platforms["linux"], TargetPlatform.linux) : null,
      windows: platforms.containsKey("windows") ? BuildConfigPlatform.fromMap(platforms["windows"], TargetPlatform.windows) : null,
      web: platforms.containsKey("web") ? BuildConfigPlatform.fromMap(platforms["web"], TargetPlatform.web) : null,
      xcodeDerivedKey: data["xcodeDerivedDataPathEnvKey"],
      cleanFlutter: data["clean_flutter"] ?? true,
    );
  }

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
