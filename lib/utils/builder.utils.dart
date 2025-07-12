import 'package:build_pipe/utils/config.utils.dart';
import 'package:build_pipe/utils/process.utils.dart';
import 'package:build_pipe/utils/web.utils.dart';

class PipeBuilder {
  static Future<int> _runBuildCommand(BuildConfig config, BuildConfigPlatform platformConfig, String userfacingPlatform) async {
    return await ProcessHelper.runCommandUsingConfig(
      executable: platformConfig.buildCommand.split(" ")[0],
      arguments: platformConfig.buildCommand.split(" ").sublist(1),
      config: config,
      startMessage: "\nBuilding $userfacingPlatform...",
      successMessage: "√ $userfacingPlatform build is done\n",
      errorMessage: "X There was an error building for $userfacingPlatform\n",
      exitIfError: false,
    );
  }

  static Future<void> buildIOS(BuildConfig config) async {
    await _runBuildCommand(config, config.ios!, "iOS");
  }

  static Future<void> buildAndroid(BuildConfig config) async {
    await _runBuildCommand(config, config.android!, "Android");
  }

  static Future<void> buildMacOS(BuildConfig config) async {
    await _runBuildCommand(config, config.macos!, "macOS");
  }

  static Future<void> buildLinux(BuildConfig config) async {
    await _runBuildCommand(config, config.linux!, "Linux");
  }

  static Future<void> buildWindows(BuildConfig config) async {
    await _runBuildCommand(config, config.windows!, "Windows");
  }

  static Future<void> buildWeb(BuildConfig config) async {
    await _runBuildCommand(config, config.web!, "Web");
    if (config.web!.addVersionQueryParam == true) {
      await WebUtils.applyCacheBustPostBuild(config);
    }
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
