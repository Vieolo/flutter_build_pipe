import 'package:build_pipe/utils/config.utils.dart';
import 'package:build_pipe/utils/process.utils.dart';

class PipeBuilder {
  static Future<int> _runBuildCommand(BuildConfig config, BuildConfigPlatform platformConfig) async {
    return await ProcessHelper.runCommand(
      executable: platformConfig.buildCommand.split(" ")[0],
      arguments: platformConfig.buildCommand.split(" ").sublist(1),
      stdoutWrite: config.printstdout,
      logFilePath: config.logFile,
    );
  }

  static Future<void> buildIOS(BuildConfig config) async {
    print("Building ios...");
    await _runBuildCommand(config, config.ios!);
    print("√ iOS build is done");
  }

  static Future<void> buildAndroid(BuildConfig config) async {
    print("Building android...");
    await _runBuildCommand(config, config.android!);
    print("√ Android build is done");
  }

  static Future<void> buildMacOS(BuildConfig config) async {
    print("Building MacOS...");
    await _runBuildCommand(config, config.macos!);
    print("√ MacOS build is done");
  }

  static Future<void> buildLinux(BuildConfig config) async {
    print("Building Linux...");
    await _runBuildCommand(config, config.linux!);
    print("√ Linux build is done");
  }

  static Future<void> buildWindows(BuildConfig config) async {
    print("Building windows...");
    await _runBuildCommand(config, config.windows!);
    print("√ Windows build is done");
  }

  static Future<void> buildWeb(BuildConfig config) async {
    print("Building web...");
    await _runBuildCommand(config, config.web!);
    print("√ Web build is done");
  }

  static Future<void> buildAll(BuildConfig config) async {
    if (config.ios != null) {
      await buildIOS(config);
    }

    if (config.android != null) {
      await buildAndroid(config);
    }

    if (config.macos != null) {
      await buildMacOS(config);
    }

    if (config.windows != null) {
      await buildWindows(config);
    }

    if (config.linux != null) {
      await buildLinux(config);
    }

    if (config.web != null) {
      await buildWeb(config);
    }
  }
}
