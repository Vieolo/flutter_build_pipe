import 'package:build_pipe/utils/console.utils.dart';

enum BPConfigValidationErrorCase {
  iosPublishValidation,
  macPublishValidation,
  androidPublishValidation,
  pubspecNotFound,
  buildPipeConfigMissing,
  noWorkflowInConfig,
  workflowNotFound,
  noTargetPlatform,
  invalidOutput,
  printStdoutReplaced,
  invalidHook,
  replacedHookKeys,
}

class BPConfigValidationError {
  BPConfigValidationErrorCase errorCase;
  String message;

  /// A warning does not stop the command, e.g. when a deprecated field is used
  bool isWarning;

  BPConfigValidationError({
    required this.errorCase,
    required this.message,
    this.isWarning = false,
  });

  void print() {
    if (isWarning) {
      Console.logWarning(message);
    } else {
      Console.logError(message);
    }
  }
}
