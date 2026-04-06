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
}

class BPConfigValidationError {
  BPConfigValidationErrorCase errorCase;
  String message;

  BPConfigValidationError({
    required this.errorCase,
    required this.message,
  });

  void print() {
    Console.logError(message);
  }
}
