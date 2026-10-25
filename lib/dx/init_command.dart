import 'dart:io';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/utils/validation.utils.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml;

/// The outcome of `build_pipe:init`
class InitResult {
  /// The platforms found in the project, which are set up in the config
  final List<TargetPlatform> platforms;

  /// The config added to the pubspec
  final String scaffold;

  const InitResult({required this.platforms, required this.scaffold});
}

/// Adds a starting build_pipe config to the pubspec of a project, for `build_pipe:init`
class InitCommand {
  /// Reads the pubspec in [projectPath] and creates the config for it, adding it to the end of the
  /// pubspec when [write] is true
  ///
  /// The pubspec is only changed when it has no build_pipe config yet, and the config is valid
  static Future<(InitResult?, String?)> run(String projectPath, {required bool write}) async {
    File pubspec = File(p.join(projectPath, "pubspec.yaml"));
    if (!await pubspec.exists()) {
      return (null, "pubspec.yaml could not be found. Run the command in the root of your Flutter project");
    }

    String content = await pubspec.readAsString();
    (yaml.YamlMap?, String?) parsed = _parse(content);
    if (parsed.$2 != null) {
      return (null, "pubspec.yaml could not be read -> ${parsed.$2}");
    }
    if (parsed.$1!.containsKey("build_pipe")) {
      return (null, "pubspec.yaml already has a build_pipe config, so nothing has been changed");
    }

    List<TargetPlatform> platforms = ConfigScaffold.detectPlatforms(projectPath);
    String scaffold = ConfigScaffold.generate(appName: parsed.$1!["name"]?.toString() ?? "your_app", platforms: platforms);
    // Separated from the rest of the pubspec by an empty line
    String updated = "$content${content.endsWith("\n") ? "" : "\n"}\n$scaffold";

    // The pubspec is checked before it is written, so that a broken config never replaces a working pubspec
    String? invalid = _checkConfig(updated);
    if (invalid != null) {
      return (null, "The generated config is invalid, so nothing has been changed -> $invalid");
    }

    if (write) {
      try {
        await pubspec.writeAsString(updated);
      } on FileSystemException catch (e) {
        return (null, "pubspec.yaml could not be written -> ${e.message}");
      }
    }
    return (InitResult(platforms: platforms, scaffold: scaffold), null);
  }

  static (yaml.YamlMap?, String?) _parse(String content) {
    try {
      dynamic parsed = yaml.loadYaml(content);
      return parsed is yaml.YamlMap ? (parsed, null) : (null, "it is not a map of fields");
    } on yaml.YamlException catch (e) {
      return (null, e.message);
    }
  }

  /// Returns why the build_pipe config of the [pubspec] is invalid, or null when it is valid
  static String? _checkConfig(String pubspec) {
    (yaml.YamlMap?, String?) parsed = _parse(pubspec);
    if (parsed.$2 != null) return parsed.$2;

    dynamic workflow = parsed.$1!["build_pipe"]?["workflows"]?["default"];
    if (workflow is! yaml.YamlMap) return "the default workflow is missing";

    (BPConfig?, List<BPConfigValidationError>) config = BPConfig.fromMap(workflow, [], "0.0.0", "0");
    if (config.$1 == null || config.$2.isNotEmpty) {
      return config.$2.map((BPConfigValidationError e) => e.message).join(", ");
    }
    return null;
  }
}

/// Creates the starting build_pipe config of a project
///
/// The platforms of the project are set up with their build command and the default values of their
/// fields, and every optional field is there but commented out. The other platforms are commented out
/// with only their build command
class ConfigScaffold {
  static const String docsUrl = "https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/install/install_intro.md";

  /// The platforms that have a folder in the project at [projectPath], in [BPConfig.platformOrder]
  static List<TargetPlatform> detectPlatforms(String projectPath) {
    return [
      for (TargetPlatform platform in BPConfig.platformOrder)
        if (Directory(p.join(projectPath, platform.name)).existsSync()) platform,
    ];
  }

  /// The config, with the [platforms] set up and everything else commented out
  static String generate({required String appName, required List<TargetPlatform> platforms}) {
    List<String> lines = [
      "# build_pipe: $docsUrl",
      "build_pipe:",
      "  workflows:",
      "    default:",
      "      clean_flutter: true",
      "      generate_log: true",
      "      output: auto # auto | interactive | plain | verbose | json",
      ..._commented(6, [
        "xcode_derived_data_path_env_key: XCODE_DERIVED_PATH",
        "pre_platform_run:",
        "  build: dart run build_runner build --delete-conflicting-outputs",
        "  publish: sh ./scripts/pre_publish.sh",
        "post_platform_run:",
        "  build:",
        "    on_success: sh ./scripts/post_build.sh",
        "    finally: sh ./scripts/build_cleanup.sh",
        "  publish:",
        "    on_success: sh ./scripts/post_publish.sh",
        "    finally: sh ./scripts/publish_cleanup.sh",
      ]),
      "      platforms:",
      for (TargetPlatform platform in BPConfig.platformOrder) ...(platforms.contains(platform) ? _indented(8, _platform(platform, appName)) : _commented(8, _missingPlatform(platform))),
    ];
    return "${lines.join("\n")}\n";
  }

  /// The config of a platform of the project
  static List<String> _platform(TargetPlatform platform, String appName) {
    String name = platform.name;
    return [
      "$name:",
      "  build:",
      "    build_command: ${_buildCommands[platform]}",
      if (platform == TargetPlatform.web) ...[
        "    add_version_query_param: true",
        "    query_param_versioning_type: hash # hash | semver",
      ],
      ..._commented(4, _hooks("${name}_pre_build", "${name}_post_build", "${name}_build_cleanup")),
      if (platform == TargetPlatform.android)
        ..._commented(2, [
          "publish:",
          "  outputFilePath: build/app/outputs/bundle/release/app-release.aab",
          "  bundleID: com.example.$appName",
          "  releaseTrack: internal # internal | alpha | beta | production",
          "  credentialPath: PLAY_API_KEY_PATH",
          ..._indented(2, _hooks("${name}_pre_publish", "${name}_post_publish", "${name}_publish_cleanup")),
        ]),
      if (platform == TargetPlatform.ios)
        ..._commented(2, [
          "publish:",
          "  keyID: IOS_APP_KEY_ID",
          "  issuerID: IOS_APP_ISSUER_ID",
          "  appAppleID: IOS_APP_APPLE_ID",
          "  bundleID: com.example.$appName",
          "  outputFilePath: build/ios/ipa/$appName.ipa",
          ..._indented(2, _hooks("${name}_pre_publish", "${name}_post_publish", "${name}_publish_cleanup")),
        ]),
    ];
  }

  /// A platform that the project does not have yet, with only its build command
  static List<String> _missingPlatform(TargetPlatform platform) {
    return ["${platform.name}:", "  build:", "    build_command: ${_buildCommands[platform]}"];
  }

  /// The `pre_command` and `post_command` of a build or a publish, running the given scripts
  static List<String> _hooks(String pre, String onSuccess, String cleanup) {
    return [
      "pre_command: sh ./scripts/$pre.sh",
      "post_command:",
      "  on_success: sh ./scripts/$onSuccess.sh",
      "  finally: sh ./scripts/$cleanup.sh",
    ];
  }

  static const Map<TargetPlatform, String> _buildCommands = {
    TargetPlatform.android: "flutter build appbundle",
    TargetPlatform.ios: "flutter build ipa",
    TargetPlatform.macos: "flutter build macos",
    TargetPlatform.windows: "flutter build windows",
    TargetPlatform.linux: "flutter build linux",
    TargetPlatform.web: "flutter build web",
  };

  static List<String> _indented(int spaces, List<String> lines) => [for (String line in lines) "${" " * spaces}$line"];

  static List<String> _commented(int spaces, List<String> lines) => [for (String line in lines) "${" " * spaces}# $line"];
}
