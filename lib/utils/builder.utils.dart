import 'dart:io';

import 'package:build_pipe/utils/config.utils.dart';

class PipeBuilder {
  static Future<void> _runBuildCommand(BuildConfigPlatform platformConfig) async {
    await Process.run(
      platformConfig.buildCommand.split(" ")[0],
      platformConfig.buildCommand.split(" ").sublist(1),
    );
  }

  static Future<void> buildIOS(BuildConfigPlatform iosConfig) async {
    print("Building ios...");
    await _runBuildCommand(iosConfig);
    print("√ iOS build is done");
  }

  static Future<void> buildAndroid(BuildConfigPlatform androidConfig) async {
    print("Building android...");
    await _runBuildCommand(androidConfig);
    print("√ Android build is done");
  }

  static Future<void> buildMacOS(BuildConfigPlatform macosConfig) async {
    print("Building MacOS...");
    await _runBuildCommand(macosConfig);
    print("√ MacOS build is done");
  }

  static Future<void> buildLinux(BuildConfigPlatform linuxConfig) async {
    print("Building Linux...");
    await _runBuildCommand(linuxConfig);
    print("√ Linux build is done");
  }

  static Future<void> buildWindows(BuildConfigPlatform windowsConfig) async {
    print("Building windows...");
    await _runBuildCommand(windowsConfig);
    print("√ Windows build is done");
  }

  static Future<void> buildWeb(BuildConfigPlatform webConfig) async {
    print("Building web...");
    await _runBuildCommand(webConfig);
    print("√ Web build is done");
  }

  static Future<void> buildAll(BuildConfig config) async {
    if (config.ios != null) {
      await buildIOS(config.ios!);
    }

    if (config.android != null) {
      await buildAndroid(config.android!);
    }

    if (config.macos != null) {
      await buildMacOS(config.macos!);
    }

    if (config.windows != null) {
      await buildWindows(config.windows!);
    }

    if (config.linux != null) {
      await buildLinux(config.linux!);
    }

    if (config.web != null) {
      await buildWeb(config.web!);
    }
  }
}
