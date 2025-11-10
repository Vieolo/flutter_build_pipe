import 'dart:io';

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
  static PlatformConfig? fromMap(yaml.YamlMap data, TargetPlatform platform) {
    // If there is no build command, the instance won't be created
    if (!data.containsKey("build_command") || data["build_command"].toString().isEmpty) {
      return null;
    }

    // The base PlatformConfig instance
    PlatformConfig pc = PlatformConfig(
      platform: platform,
      buildCommand: data["build_command"],
    );

    // -=-=-=-=-=
    // Web
    // -=-=-=-=-=
    if (platform == TargetPlatform.web) {
      pc.webConfig = WebConfig(
        addVersionQueryParam: (data['add_version_query_param'] ?? true),
        webVersioningType: WebVersioningType.getByName(data['query_param_versioning_type']),
      );
    }

    // -=-=-=-=-=
    // iOS
    // -=-=-=-=-=
    if (platform == TargetPlatform.ios) {
      if (data.containsKey("publish")) {
        var iosPublishValidation = ApplePublishConfig.isValid(data["publish"], TargetPlatform.ios);
        if (!iosPublishValidation.$1) {
          Console.logError("Invalid publish config for iOS -> ${iosPublishValidation.$2 ?? "-"}");
          exit(1);
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
          Console.logError("Invalid publish config for macOS -> ${macosPublishValidation.$2 ?? "-"}");
          exit(1);
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
          Console.logError("Invalid publish config for Android -> ${androidPublishValidation.$2 ?? "-"}");
          exit(1);
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

    return pc;
  }
}
