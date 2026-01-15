import 'package:build_pipe/config/android_specific_config.dart';
import 'package:build_pipe/config/apple_specific_config.dart';
import 'package:build_pipe/config/web_specific_config.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:yaml/yaml.dart' as yaml;

/// The platforms the application will be built for
enum TargetPlatform { web, ios, android, macos, windows, linux }

class WindowsConfig {}

class LinuxConfig {}

/// Config for a specific platform
///
/// It holds the name of the platform, the build command, and
/// an embedded class holding the config specific for the platform
class PlatformConfig {
  // config present in all platforms
  //
  // If a config is given, it must have the following
  // fields
  TargetPlatform platform;
  String buildCommand;

  // Platform config
  //
  // These instances will only hold platform specific
  // fields
  IOSConfig? iosConfig;
  MacOSConfig? macOSConfig;
  AndroidConfig? androidConfig;
  WindowsConfig? windowsConfig;
  LinuxConfig? linuxConfig;
  WebConfig? webConfig;

  PlatformConfig({
    required this.platform,
    required this.buildCommand,
    this.iosConfig,
    this.macOSConfig,
    this.androidConfig,
    this.windowsConfig,
    this.linuxConfig,
    this.webConfig,
  });

  /// Parses a map to `PlatformConfig`
  static (PlatformConfig?, List<(Function(String s), String)>) fromMap(yaml.YamlMap platformsObject, TargetPlatform platform, String key) {
    if (!platformsObject.containsKey(key)) {
      return (null, []);
    }
    yaml.YamlMap data = platformsObject[key];
    String? buildCommand;
    bool hasBuild = false;

    if (data.containsKey("build")) {
      dynamic buildData = data["build"];
      if (buildData is Map && buildData.containsKey("build_command") && buildData["build_command"].toString().isNotEmpty) {
        buildCommand = buildData["build_command"];
        hasBuild = buildCommand != null && buildCommand.isNotEmpty;
      }
    }

    // The build config is optional. A platform config can have only a publish config
    // At the moment, only iOS and Android publish config is supported
    // So, if the build config is missing and the platform is not iOS or Android, the config is invalid
    if (!hasBuild) {
      if (platform == TargetPlatform.ios || platform == TargetPlatform.android) {
        bool hasPublish = data.containsKey("publish");
        if (!hasPublish) {
          return (null, []);
        }
      } else {
        return (null, []);
      }
    }

    // The base PlatformConfig instance
    PlatformConfig pc = PlatformConfig(
      platform: platform,
      buildCommand: buildCommand ?? "",
    );

    // -=-=-=-=-=
    // Web
    // -=-=-=-=-=
    if (platform == TargetPlatform.web) {
      dynamic buildData = data["build"];
      pc.webConfig = WebConfig(
        addVersionQueryParam: (buildData['add_version_query_param'] ?? true),
        webVersioningType: WebVersioningType.getByName(buildData['query_param_versioning_type']),
      );
    }

    // -=-=-=-=-=
    // iOS
    // -=-=-=-=-=
    if (platform == TargetPlatform.ios) {
      if (data.containsKey("publish")) {
        var iosPublishValidation = ApplePublishConfig.isValid(data["publish"], TargetPlatform.ios);
        if (!iosPublishValidation.$1) {
          return (null, [(Console.logError, "Invalid publish config for iOS -> ${iosPublishValidation.$2 ?? "-"}")]);
        }
        pc.iosConfig = IOSConfig(
          publishConfig: ApplePublishConfig.fromMap(data["publish"]),
        );
      }
    }

    // -=-=-=-=-=
    // macOS
    // -=-=-=-=-=
    if (platform == TargetPlatform.macos) {
      if (data.containsKey("publish")) {
        var macosPublishValidation = ApplePublishConfig.isValid(data["publish"], TargetPlatform.macos);
        if (!macosPublishValidation.$1) {
          return (null, [(Console.logError, "Invalid publish config for macOS -> ${macosPublishValidation.$2 ?? "-"}")]);
        }
        pc.macOSConfig = MacOSConfig(
          publishConfig: ApplePublishConfig.fromMap(data["publish"]),
        );
      }
    }

    // -=-=-=-=-=
    // Android
    // -=-=-=-=-=
    if (platform == TargetPlatform.android) {
      if (data.containsKey("publish")) {
        var androidPublishValidation = AndroidPublishConfig.isValid(data["publish"], TargetPlatform.android);
        if (!androidPublishValidation.$1) {
          return (null, [(Console.logError, "Invalid publish config for Android -> ${androidPublishValidation.$2 ?? "-"}")]);
        }
        pc.androidConfig = AndroidConfig(
          publishConfig: AndroidPublishConfig.fromMap(data["publish"]),
        );
      }
    }

    // -=-=-=-=-=
    // Linux
    // -=-=-=-=-=
    if (platform == TargetPlatform.linux) {
      pc.linuxConfig = LinuxConfig();
    }

    // -=-=-=-=-=
    // Windows
    // -=-=-=-=-=
    if (platform == TargetPlatform.windows) {
      pc.windowsConfig = WindowsConfig();
    }

    return (pc, []);
  }
}
