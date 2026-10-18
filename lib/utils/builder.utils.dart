import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/config/web_specific_config.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:build_pipe/utils/web.utils.dart';

/// The utility class for creating the build steps
/// of different platforms
class PipeBuilder {
  /// The user-facing names of the platforms
  static const Map<TargetPlatform, String> _platformNames = {
    TargetPlatform.ios: "iOS",
    TargetPlatform.android: "Android",
    TargetPlatform.macos: "macOS",
    TargetPlatform.linux: "Linux",
    TargetPlatform.windows: "Windows",
    TargetPlatform.web: "Web",
  };

  /// The build steps of all platforms mentioned in the config, in order
  static List<PipeStep> buildSteps(BPConfig config) {
    List<PipeStep> steps = [];
    for (final platform in config.buildPlatforms) {
      PlatformConfig? platformConfig = switch (platform) {
        TargetPlatform.ios => config.ios,
        TargetPlatform.android => config.android,
        TargetPlatform.macos => config.macos,
        TargetPlatform.linux => config.linux,
        TargetPlatform.windows => config.windows,
        TargetPlatform.web => config.web,
      };

      // Safety check in case an empty build command is passed
      // and the lack of build command is not caught by the config parser
      if (platformConfig == null || platformConfig.buildCommand.isEmpty) continue;

      String name = _platformNames[platform]!;
      List<PipeStep> postBuildSteps = _postBuildSteps(config, platform);

      // The extra steps of a platform are shown under it, so a platform with extra steps becomes a group.
      // Being in a group, the extra steps are skipped when the build fails
      steps.add(
        postBuildSteps.isEmpty
            ? _buildCommandStep(config, platformConfig, name)
            : StepGroup(name, [
                _buildCommandStep(config, platformConfig, "Build"),
                ...postBuildSteps,
              ]),
      );
    }
    return steps;
  }

  /// The step running the build command of a platform
  static PipeStep _buildCommandStep(BPConfig config, PlatformConfig platformConfig, String label) {
    return CommandStep.fromString(
      label,
      platformConfig.buildCommand,
      // Appending any additional command line arguments passed down from build_pipe:build command
      extraArguments: config.cmdArgs,
    );
  }

  /// The steps run after the build command of a platform, e.g. the cache busting of web
  static List<PipeStep> _postBuildSteps(BPConfig config, TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.web:
        if (config.web?.webConfig?.addVersionQueryParam != true) return [];
        WebVersioningType versioningType = config.web?.webConfig?.webVersioningType ?? WebVersioningType.hash;
        return [
          ActionStep(
            "Cache bust (${versioningType.isHash ? "hash" : "version ${config.version}"})",
            (StepContext context) => WebUtils.applyCacheBustPostBuild(config, context),
          ),
        ];
      case TargetPlatform.ios:
      case TargetPlatform.android:
      case TargetPlatform.macos:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return [];
    }
  }
}
