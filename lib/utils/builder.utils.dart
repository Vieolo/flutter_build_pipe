import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/config/web_specific_config.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:build_pipe/utils/web.utils.dart';

/// The utility class for creating the build steps
/// of different platforms. The steps are put in order by `PipePlan`
class PipeBuilder {
  /// The step running the build command of a platform
  static PipeStep buildCommandStep(BPConfig config, PlatformConfig platformConfig, String label) {
    return CommandStep.fromString(
      label,
      platformConfig.buildCommand,
      // Appending any additional command line arguments passed down from build_pipe:build command
      extraArguments: config.cmdArgs,
    );
  }

  /// The steps run after the build command of a platform, e.g. the cache busting of web
  static List<PipeStep> extraBuildSteps(BPConfig config, TargetPlatform platform) {
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
