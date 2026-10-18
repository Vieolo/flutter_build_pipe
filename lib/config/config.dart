import 'dart:io';

import 'package:build_pipe/config/hook_config.dart';
import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/runner/output_mode.dart';
import 'package:build_pipe/utils/validation.utils.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml;

/// The actual class holding the fields of the config
class BPConfig {
  PlatformConfig? web;
  PlatformConfig? ios;
  PlatformConfig? android;
  PlatformConfig? macos;
  PlatformConfig? windows;
  PlatformConfig? linux;
  String? xcodeDerivedKey;
  bool cleanFlutter;

  /// How the run is shown, from the `output` field of the workflow or the `--bp-output` flag
  OutputMode output;
  DateTime timestamp;
  String version;
  String buildVersion;
  bool generateLog;

  /// The `pre_platform_run.build` and `post_platform_run.build` of the workflow
  HookCommands buildHooks;

  /// The `pre_platform_run.publish` and `post_platform_run.publish` of the workflow
  HookCommands publishHooks;
  List<String> cmdArgs;
  String workflowName;

  BPConfig({
    this.android,
    this.ios,
    this.linux,
    this.macos,
    this.web,
    this.windows,
    this.xcodeDerivedKey,
    this.buildHooks = const HookCommands(),
    this.publishHooks = const HookCommands(),
    required this.cleanFlutter,
    this.output = OutputMode.auto,
    required this.timestamp,
    required this.version,
    required this.generateLog,
    required this.buildVersion,
    required this.cmdArgs,
    this.workflowName = "default",
  });

  /// Parsed the config from the map
  static (BPConfig?, List<BPConfigValidationError>) fromMap(
    yaml.YamlMap data,
    List<String> args,
    String version,
    String buildVersion, {
    String workflowName = "default",
  }) {
    BPConfigValidationError? replacedKeys = _replacedHookKeys(data, workflowName);
    if (replacedKeys != null) {
      return (null, [replacedKeys]);
    }

    yaml.YamlMap platforms = data["platforms"] ?? yaml.YamlMap();
    (PlatformConfig?, List<BPConfigValidationError>) android = PlatformConfig.fromMap(platforms, TargetPlatform.android, "android");
    (PlatformConfig?, List<BPConfigValidationError>) iOS = PlatformConfig.fromMap(platforms, TargetPlatform.ios, "ios");
    (PlatformConfig?, List<BPConfigValidationError>) macos = PlatformConfig.fromMap(platforms, TargetPlatform.macos, "macos");
    (PlatformConfig?, List<BPConfigValidationError>) linux = PlatformConfig.fromMap(platforms, TargetPlatform.linux, "linux");
    (PlatformConfig?, List<BPConfigValidationError>) windows = PlatformConfig.fromMap(platforms, TargetPlatform.windows, "windows");
    (PlatformConfig?, List<BPConfigValidationError>) web = PlatformConfig.fromMap(platforms, TargetPlatform.web, "web");

    (OutputMode?, List<BPConfigValidationError>) output = _outputFromMap(data);
    if (output.$1 == null) {
      return (null, output.$2);
    }

    // A mistake in a hook stops the whole command, since running the wrong hook, or none, can have
    // unintended consequences, e.g. publishing a failed build
    (({HookCommands build, HookCommands publish})?, List<BPConfigValidationError>) hooks = HookCommands.fromWorkflow(data);
    List<BPConfigValidationError> platformErrors = [...android.$2, ...iOS.$2, ...macos.$2, ...linux.$2, ...windows.$2, ...web.$2];
    List<BPConfigValidationError> hookErrors = [
      ...hooks.$2,
      ...platformErrors.where((BPConfigValidationError e) => e.errorCase == BPConfigValidationErrorCase.invalidHook),
    ];
    if (hookErrors.isNotEmpty) {
      return (null, hookErrors);
    }

    return (
      BPConfig(
        android: android.$1,
        ios: iOS.$1,
        macos: macos.$1,
        linux: linux.$1,
        windows: windows.$1,
        web: web.$1,
        xcodeDerivedKey: data["xcode_derived_data_path_env_key"],
        cleanFlutter: data["clean_flutter"] ?? true,
        generateLog: data["generate_log"] ?? true,
        output: output.$1!,
        buildHooks: hooks.$1!.build,
        publishHooks: hooks.$1!.publish,
        timestamp: DateTime.now(),
        version: version,
        buildVersion: buildVersion,
        cmdArgs: args,
        workflowName: workflowName,
      ),
      [...output.$2, ...platformErrors],
    );
  }

  /// Checks for `pre_build_command` and `post_build_command`, which are replaced by `pre_platform_run` and `post_platform_run`
  ///
  /// The old keys are not mapped to the new ones, since `post_build_command` ran whether the builds had
  /// failed or not, and its replacement, `on_success` or `finally`, has to be chosen by the user
  static BPConfigValidationError? _replacedHookKeys(yaml.YamlMap data, String workflowName) {
    Map<String, String> replacements = {
      "pre_build_command": "'pre_platform_run.build'",
      "post_build_command": "'post_platform_run.build.on_success' (runs when nothing has failed) or 'post_platform_run.build.finally' (runs whether anything has failed or not)",
    };
    List<String> found = replacements.keys.where(data.containsKey).toList();
    if (found.isEmpty) return null;

    return BPConfigValidationError(
      errorCase: BPConfigValidationErrorCase.replacedHookKeys,
      message: [
        "The workflow '$workflowName' uses keys that are no longer supported, so nothing has been run:",
        for (String key in found) "  - '$key' is replaced by ${replacements[key]}",
        "Please update the workflow, using the migration guide: https://github.com/vieolo/flutter_build_pipe/blob/master/doc/migration/0_3_to_0_4.md",
      ].join("\n"),
    );
  }

  /// Reads the `output` field of a workflow
  ///
  /// Before `output`, the workflows had `print_stdout`, which is still read when `output` is missing.
  /// `print_stdout: true` printed the whole output of the commands, which is now `output: verbose`
  static (OutputMode?, List<BPConfigValidationError>) _outputFromMap(yaml.YamlMap data) {
    List<BPConfigValidationError> warnings = [];
    if (data.containsKey("print_stdout")) {
      warnings.add(
        BPConfigValidationError(
          errorCase: BPConfigValidationErrorCase.printStdoutReplaced,
          message: "'print_stdout' is replaced by 'output' and will be removed in a future version. Use 'output: verbose' instead of 'print_stdout: true', or remove 'print_stdout: false'",
          isWarning: true,
        ),
      );
    }

    if (data["output"] == null) {
      return (data["print_stdout"] == true ? OutputMode.verbose : OutputMode.auto, warnings);
    }

    (OutputMode?, String?) parsed = OutputMode.parse(data["output"].toString());
    if (parsed.$2 != null) {
      return (
        null,
        [
          BPConfigValidationError(
            errorCase: BPConfigValidationErrorCase.invalidOutput,
            message: "Invalid 'output' in the workflow -> ${parsed.$2}",
          ),
        ],
      );
    }
    return (parsed.$1, warnings);
  }

  /// Gets the path of the log file, if log generation is not prevented via the config
  String get logFile {
    String fileName = "${timestamp.toIso8601String()}.log";

    // In windows, it seems that, the file name cannot
    // contain `:`
    if (Platform.isWindows) {
      fileName = fileName.replaceAll(":", "_");
    }

    return generateLog
        ? p.join(
            Directory.current.path,
            ".flutter_build_pipe",
            "logs",
            version,
            fileName,
          )
        : "";
  }

  /// Checks if the XCode derived data is provided AND there is a build target for Apple devices
  bool get needXCodeDerivedCleaning => (ios != null || macos != null) && xcodeDerivedKey != null && xcodeDerivedKey!.isNotEmpty;

  /// The order the platforms always run in, whatever their order in the pubspec or in `--override-target-platforms`
  static const List<TargetPlatform> platformOrder = [
    TargetPlatform.android,
    TargetPlatform.ios,
    TargetPlatform.macos,
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.web,
  ];

  /// The config of the given platform, if the workflow has one
  PlatformConfig? platformConfig(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android => android,
      TargetPlatform.ios => ios,
      TargetPlatform.macos => macos,
      TargetPlatform.windows => windows,
      TargetPlatform.linux => linux,
      TargetPlatform.web => web,
    };
  }

  /// The list of target platforms provided in the config for building, in [platformOrder]
  /// iOS and android config may exist without a build command, in which case
  /// they will not be returned
  /// All other platforms, since they do not have a publish config yet, will
  /// return if have a config
  List<TargetPlatform> get buildPlatforms => [
    for (TargetPlatform platform in platformOrder)
      if (platformConfig(platform) != null && platformConfig(platform)!.buildCommand.isNotEmpty) platform,
  ];

  /// The list of target platforms provided in the config for publishing, in [platformOrder]
  /// Only iOS and Android are supported for publishing at the moment, and they
  /// will be returned if they have a publish config
  List<TargetPlatform> get publishPlatforms => [
    if (android != null && android!.androidConfig?.publishConfig != null) TargetPlatform.android,
    if (ios != null && ios!.iosConfig?.publishConfig != null) TargetPlatform.ios,
  ];

  /// Reads the `pubspec.yaml` file, parses, validates, and returns
  /// the config object. No exceptions are thrown from this functions,
  /// instead, a list of user-facing errors will be returned as
  /// the second object of the record
  static Future<(BPConfig?, List<BPConfigValidationError>)> readPubspec(List<String> args, [String? pubspecPath]) async {
    final rawPubspecFile = File(pubspecPath ?? 'pubspec.yaml');
    if (!(await rawPubspecFile.exists())) {
      return (
        null,
        [
          BPConfigValidationError(
            errorCase: BPConfigValidationErrorCase.pubspecNotFound,
            message: "pubspec.yaml file could not be found!",
          ),
        ],
      );
    }

    final pubspec = yaml.loadYaml(await rawPubspecFile.readAsString());
    if (!(pubspec as yaml.YamlMap).containsKey("build_pipe")) {
      return (
        null,
        [
          BPConfigValidationError(
            errorCase: BPConfigValidationErrorCase.buildPipeConfigMissing,
            message: "please add the build_pipe configuration to your pubspec file!",
          ),
        ],
      );
    }

    var buildPipeConfig = pubspec["build_pipe"];

    if (!buildPipeConfig.containsKey("workflows")) {
      List<String> messages = [
        "No 'workflows' found in build_pipe config.",
      ];
      // In 0.3.0, the named workflows were introduced which is a breaking change to the config structure.
      // Prior to 0.3.0, the `build_pipe` object contains the config directly, practically for
      // a single workflow. If the `workflows` key is missing and the `platforms` is present, it is an
      // indication that the user is using an older version of the package.
      if (buildPipeConfig.containsKey("platforms")) {
        messages.add("It seems that you have updated the flutter_build_pipe package to version 0.3.0 or higher. This version contains breaking changes in the configuration.");
        messages.add("You need to make some changes to your pubspec.yaml file, which should take less than a minute.");
        messages.add("Please read the migration guide here: https://github.com/vieolo/flutter_build_pipe/blob/master/doc/migration/0_3_0.md");
      }

      return (
        null,
        [
          BPConfigValidationError(
            errorCase: BPConfigValidationErrorCase.noWorkflowInConfig,
            message: messages.join("\n"),
          ),
        ],
      );
    }

    // The flag overrides the `output` of the workflow
    (OutputMode?, String?) outputFlag = OutputMode.fromArgs(args);
    if (outputFlag.$2 != null) {
      return (
        null,
        [
          BPConfigValidationError(
            errorCase: BPConfigValidationErrorCase.invalidOutput,
            message: outputFlag.$2!,
          ),
        ],
      );
    }

    String workflowName = "default";
    List<String> overriddenTargetPlatforms = [];
    List<String> downstreamargs = [];
    for (var arg in args) {
      if (OutputMode.isFlag(arg)) {
        continue;
      }
      if (arg.startsWith("--workflow=")) {
        workflowName = arg.split("=")[1];
        continue;
      }
      if (arg.startsWith("--override-target-platforms=")) {
        overriddenTargetPlatforms = arg.split("=")[1].split(",");
        continue;
      }
      downstreamargs.add(arg);
    }

    var workflows = buildPipeConfig["workflows"];
    if (!workflows.containsKey(workflowName)) {
      return (
        null,
        [
          BPConfigValidationError(
            errorCase: BPConfigValidationErrorCase.workflowNotFound,
            message: "Workflow '$workflowName' not found.",
          ),
        ],
      );
    }

    final (BPConfig?, List<BPConfigValidationError>) config = BPConfig.fromMap(
      workflows[workflowName],
      downstreamargs,
      pubspec["version"].split("+")[0],
      // just in case the + doesnt exist
      pubspec["version"].split("+").length > 1 ? pubspec["version"].split("+")[1] : "0",
      workflowName: workflowName,
    );

    if (config.$1 != null && outputFlag.$1 != null) {
      config.$1!.output = outputFlag.$1!;
    }

    if (config.$1 != null && overriddenTargetPlatforms.isNotEmpty) {
      config.$1?._applyTargetPlatformFilter(overriddenTargetPlatforms);
    }

    if (config.$1 != null && config.$1!.publishPlatforms.isEmpty && config.$1!.buildPlatforms.isEmpty) {
      return (
        null,
        [
          BPConfigValidationError(
            errorCase: BPConfigValidationErrorCase.noTargetPlatform,
            message: "No target platforms were detected. Please add your target platforms to pubspec",
          ),
        ],
      );
    }

    return config;
  }

  /// This function will apply the value of `override-target-platforms` cli option
  ///
  /// Any target platform which is not mentioned in the value will be removed. If no
  /// matching value is given, the list of the target platforms will be empty, returning
  /// an error
  void _applyTargetPlatformFilter(List<String> allowedTargets) {
    final targets = allowedTargets.map((e) => e.toLowerCase().trim()).toList();
    if (!targets.contains("android")) android = null;
    if (!targets.contains("ios")) ios = null;
    if (!targets.contains("macos")) macos = null;
    if (!targets.contains("linux")) linux = null;
    if (!targets.contains("windows")) windows = null;
    if (!targets.contains("web")) web = null;
  }
}
