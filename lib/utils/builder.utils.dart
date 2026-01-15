import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/utils/process.utils.dart';
import 'package:build_pipe/utils/web.utils.dart';

/// The utility class for performing the builds
/// for different platforms
class PipeBuilder {
  /// The actual function running the build command
  /// This function is private and is called via platform specific interface
  static Future<(int, List<String>)> _runBuildCommand(
    BPConfig config,
    PlatformConfig platformConfig,
    String userfacingPlatform,
  ) async {
    // Safety check in case an empty build command is passed
    // and the lack of build command is not caught by the config parser
    if (platformConfig.buildCommand.isEmpty) {
      return (0, <String>[]);
    }

    final buildCommand = platformConfig.buildCommand.split(" ");
    return await ProcessHelper.runCommandUsingConfig(
      executable: buildCommand[0],
      // Appending any additional command line arguments passed down from build_pipe:build command
      arguments: buildCommand.sublist(1) + config.cmdArgs,
      config: config,
      startMessage: "└── Building $userfacingPlatform...",
      clearStartMessage: true,
      successMessage: "└── √ $userfacingPlatform build is done\n",
      errorMessage: "└── X There was an error building for $userfacingPlatform\n",
      exitIfError: false,
    );
  }

  /// Builds for `iOS`
  static Future<void> buildIOS(BPConfig config) async {
    await _runBuildCommand(config, config.ios!, "iOS");
  }

  /// Builds for `Android`
  static Future<void> buildAndroid(BPConfig config) async {
    await _runBuildCommand(config, config.android!, "Android");
  }

  /// Builds for `macOS`
  static Future<void> buildMacOS(BPConfig config) async {
    await _runBuildCommand(config, config.macos!, "macOS");
  }

  /// Builds for `Linux`
  static Future<void> buildLinux(BPConfig config) async {
    await _runBuildCommand(config, config.linux!, "Linux");
  }

  /// Builds for `Windows`
  static Future<void> buildWindows(BPConfig config) async {
    await _runBuildCommand(config, config.windows!, "Windows");
  }

  /// Builds for `web`
  /// After the build process is completed, if not prevented
  /// via the pubspec config, it will handle the web cache busting as well
  static Future<void> buildWeb(BPConfig config) async {
    await _runBuildCommand(config, config.web!, "Web");
    if (config.web!.webConfig!.addVersionQueryParam == true) {
      await WebUtils.applyCacheBustPostBuild(config);
    }
  }

  /// Initiates the build for all platforms mentioned
  /// in the config
  static Future<void> buildAll(BPConfig config) async {
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
