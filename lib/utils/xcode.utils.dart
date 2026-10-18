import 'dart:io';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/runner/pipe_step.dart';

/// Utility class for XCode specific functionalities
class XCodeUtils {
  /// The step deleting the derived data of the XCode before the build
  /// to prevent faulty caches affecting the production build
  ///
  /// The path of the derived data is read from the env variable named by `xcode_derived_data_path_env_key`
  static PipeStep deleteDerivedDataStep(BPConfig config) {
    return ActionStep("Delete the XCode derived data", (StepContext context) async {
      String key = config.xcodeDerivedKey ?? "";
      String? derivedPath = Platform.environment[key];
      if (derivedPath == null || derivedPath.isEmpty) {
        context.warn("$key is either not a valid environmental variable or has an empty value, so the derived data is not deleted");
        return null;
      }

      Directory dir = Directory(derivedPath);
      if (!await dir.exists()) {
        return StepError("the given path for the XCode derived data is invalid", details: [derivedPath]);
      }

      try {
        await dir.delete(recursive: true);
      } on FileSystemException catch (e) {
        return StepError("the derived data could not be deleted", details: [e.toString()]);
      }
      context.log("deleted $derivedPath");
      return null;
    });
  }
}
