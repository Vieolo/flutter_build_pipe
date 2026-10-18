import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:build_pipe/utils/process.utils.dart';
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

      if (platform == TargetPlatform.web) {
        steps.add(_webBuildStep(config, platformConfig));
      } else {
        steps.add(
          CommandStep.fromString(
            _platformNames[platform]!,
            platformConfig.buildCommand,
            // Appending any additional command line arguments passed down from build_pipe:build command
            extraArguments: config.cmdArgs,
          ),
        );
      }
    }
    return steps;
  }

  /// Builds for `web`
  /// After the build process is completed, if not prevented
  /// via the pubspec config, it will handle the web cache busting as well
  static PipeStep _webBuildStep(BPConfig config, PlatformConfig platformConfig) {
    return ActionStep(_platformNames[TargetPlatform.web]!, (StepContext context) async {
      List<String> buildCommand = ProcessHelper.splitCommand(platformConfig.buildCommand);
      StepError? buildError = StepError.fromCommand(
        await context.runCommand(buildCommand.first, [...buildCommand.skip(1), ...config.cmdArgs]),
      );
      // There is nothing to apply the cache bust to, when the build has failed
      if (buildError != null) return buildError;

      if (platformConfig.webConfig?.addVersionQueryParam == true) {
        return await WebUtils.applyCacheBustPostBuild(config, context);
      }
      return null;
    });
  }
}
