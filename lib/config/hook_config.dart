import 'package:build_pipe/utils/validation.utils.dart';
import 'package:yaml/yaml.dart' as yaml;

/// The commands run around a part of a run
///
/// In a workflow, they are set by `pre_platform_run` and `post_platform_run`, and run around all the
/// platforms. In the `build` or `publish` of a platform, they are set by `pre_command` and `post_command`,
/// and run around the build or the publish of that platform
class HookCommands {
  /// Runs first. When it fails, everything after it is skipped, except for [finallyCommand]
  final String? pre;

  /// Runs when nothing has failed before it
  final String? onSuccess;

  /// Runs last, whether anything has failed before it or not. Set by the `finally` key, which is a
  /// reserved word in Dart
  final String? finallyCommand;

  const HookCommands({this.pre, this.onSuccess, this.finallyCommand});

  bool get isEmpty => pre == null && onSuccess == null && finallyCommand == null;

  /// The keys of the `post_command` and `post_platform_run.<command>` objects
  static const List<String> postKeys = ["on_success", "finally"];

  /// The build_pipe commands that `pre_platform_run` and `post_platform_run` have hooks for
  static const List<String> commands = ["build", "publish"];

  /// Reads the `pre_command` and `post_command` of the `build` or `publish` of a platform
  ///
  /// The [where] is the path of the block, e.g. `platforms.ios.build`, used in the errors
  static (HookCommands?, List<BPConfigValidationError>) fromPlatformBlock(dynamic block, String where) {
    if (block is! Map) return (const HookCommands(), []);

    List<String> errors = [];
    String? pre = block.containsKey("pre_command") ? _command(block["pre_command"], "$where.pre_command", errors) : null;
    (String?, String?) post = block.containsKey("post_command") ? _post(block["post_command"], "$where.post_command", errors) : (null, null);

    if (errors.isNotEmpty) return (null, _toErrors(errors));
    return (HookCommands(pre: pre, onSuccess: post.$1, finallyCommand: post.$2), []);
  }

  /// Reads the `pre_platform_run` and `post_platform_run` of a workflow, for both the build and the publish commands
  static (({HookCommands build, HookCommands publish})?, List<BPConfigValidationError>) fromWorkflow(yaml.YamlMap workflow) {
    List<String> errors = [];
    Map<String, String?> pre = {};
    Map<String, (String?, String?)> post = {};

    if (workflow.containsKey("pre_platform_run")) {
      Map? preRun = _commandsObject(workflow["pre_platform_run"], "pre_platform_run", errors);
      for (String command in commands) {
        if (preRun != null && preRun.containsKey(command)) {
          pre[command] = _command(preRun[command], "pre_platform_run.$command", errors);
        }
      }
    }

    if (workflow.containsKey("post_platform_run")) {
      Map? postRun = _commandsObject(workflow["post_platform_run"], "post_platform_run", errors);
      for (String command in commands) {
        if (postRun != null && postRun.containsKey(command)) {
          post[command] = _post(postRun[command], "post_platform_run.$command", errors);
        }
      }
    }

    if (errors.isNotEmpty) return (null, _toErrors(errors));

    HookCommands hooksOf(String command) {
      return HookCommands(pre: pre[command], onSuccess: post[command]?.$1, finallyCommand: post[command]?.$2);
    }

    return ((build: hooksOf("build"), publish: hooksOf("publish")), []);
  }

  /// Checks that the value of `pre_platform_run` or `post_platform_run` is an object of the build_pipe commands
  static Map? _commandsObject(dynamic value, String where, List<String> errors) {
    if (value is! Map) {
      errors.add("'$where' must be an object with the 'build' and/or 'publish' keys");
      return null;
    }
    _checkKeys(value, commands, where, errors);
    return value;
  }

  /// Reads a `post_command` or `post_platform_run.<command>` object, returning its `on_success` and `finally`
  static (String?, String?) _post(dynamic value, String where, List<String> errors) {
    if (value is! Map) {
      errors.add("'$where' must be an object with the 'on_success' and/or 'finally' keys");
      return (null, null);
    }
    _checkKeys(value, postKeys, where, errors);
    return (
      value.containsKey("on_success") ? _command(value["on_success"], "$where.on_success", errors) : null,
      value.containsKey("finally") ? _command(value["finally"], "$where.finally", errors) : null,
    );
  }

  /// Reads a command, which must be a non-empty string
  static String? _command(dynamic value, String where, List<String> errors) {
    if (value is! String || value.trim().isEmpty) {
      errors.add("'$where' must be a command, e.g. 'sh ./scripts/hook.sh'");
      return null;
    }
    return value;
  }

  /// A misspelled key would make a hook never run without anyone noticing, so every unknown key is an error
  static void _checkKeys(Map value, List<String> allowed, String where, List<String> errors) {
    for (dynamic key in value.keys) {
      if (!allowed.contains(key)) {
        errors.add("'$where' has the unknown key '$key'. The allowed keys are: ${allowed.join(", ")}");
      }
    }
  }

  static List<BPConfigValidationError> _toErrors(List<String> messages) {
    return [for (String message in messages) BPConfigValidationError(errorCase: BPConfigValidationErrorCase.invalidHook, message: message)];
  }
}
