import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/runner/output_mode.dart';
import 'package:build_pipe/utils/validation.utils.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Config Parsing', () {
    test('Should detect the pre-0.3.0 config', () async {
      var configAndErrors = await BPConfig.readPubspec([], "test/sample/pre_0_3_0_config.yaml");
      expect(configAndErrors.$1, isNull);
      expect(configAndErrors.$2.last.message.split("\n"), hasLength(4));
      expect(configAndErrors.$2.last.message.contains("Please read the migration guide here: https://github.com/vieolo/flutter_build_pipe/blob/master/doc/migration/0_3_0.md"), true);
    });

    test('Should parse a valid config', () async {
      var configAndErrors = await BPConfig.readPubspec([], "test/sample/valid_all_options.yaml");
      expect(configAndErrors.$1, isNotNull);
      expect(configAndErrors.$2, hasLength(1));
    });

    test('Should parse the config with explicit workflow', () async {
      var configAndErrors = await BPConfig.readPubspec(["--workflow=default"], "test/sample/valid_all_options.yaml");
      expect(configAndErrors.$1, isNotNull);
      expect(configAndErrors.$2, hasLength(1));
    });

    test('Should detect non-existing workflow', () async {
      var configAndErrors = await BPConfig.readPubspec(["--workflow=something"], "test/sample/valid_all_options.yaml");
      expect(configAndErrors.$1, isNull);
      expect(configAndErrors.$2, hasLength(1));
      expect(configAndErrors.$2.last.errorCase, BPConfigValidationErrorCase.workflowNotFound);
    });

    test('Should detect missing platforms', () async {
      var configAndErrors = await BPConfig.readPubspec([], "test/sample/missing_platforms.yaml");
      expect(configAndErrors.$1, isNull);
      expect(configAndErrors.$2, hasLength(1));
      expect(configAndErrors.$2.last.errorCase, BPConfigValidationErrorCase.noTargetPlatform);

      configAndErrors = await BPConfig.readPubspec(["--workflow=with_empty_build"], "test/sample/missing_platforms.yaml");
      expect(configAndErrors.$1, isNull);
      expect(configAndErrors.$2, hasLength(1));
      expect(configAndErrors.$2.last.errorCase, BPConfigValidationErrorCase.noTargetPlatform);
    });
  });

  test('Should filter platforms using --override-target-platforms', () async {
    var singleTarget = await BPConfig.readPubspec(
      ["--override-target-platforms=android"],
      "test/sample/valid_all_options.yaml",
    );
    expect(singleTarget.$1, isNotNull);
    expect(singleTarget.$1!.buildPlatforms, hasLength(1));
    expect(singleTarget.$1!.buildPlatforms.first.name, "android");
    expect(singleTarget.$1!.cmdArgs, isNot(contains("--override-target-platforms=android")));

    var multiTarget = await BPConfig.readPubspec(
      ["--override-target-platforms=android,web,macos"],
      "test/sample/valid_all_options.yaml",
    );
    expect(multiTarget.$1, isNotNull);
    expect(multiTarget.$1!.buildPlatforms, hasLength(3));
    final names = multiTarget.$1!.buildPlatforms.map((p) => p.name).toList();
    expect(names, containsAll(["android", "web", "macos"]));

    var capsTarget = await BPConfig.readPubspec(
      ["--override-target-platforms=ANDROID"],
      "test/sample/valid_all_options.yaml",
    );
    expect(capsTarget.$1!.buildPlatforms, hasLength(1));
  });

  test('Should return error if filtered targets result in empty list', () async {
    var errorTarget = await BPConfig.readPubspec(
      ["--override-target-platforms=nokia_3310"],
      "test/sample/valid_all_options.yaml",
    );

    expect(errorTarget.$1, isNull);
    expect(errorTarget.$2.last.errorCase, BPConfigValidationErrorCase.noTargetPlatform);
  });

  group('Output', () {
    /// Parses a workflow without platforms, which is enough for the output
    (BPConfig?, List<BPConfigValidationError>) parseWorkflow(String yaml) => BPConfig.fromMap(loadYaml(yaml) as YamlMap, [], "1.0.0", "1");

    test('reads the output of the workflow', () async {
      var configAndErrors = await BPConfig.readPubspec([], "test/sample/valid_all_options.yaml");
      expect(configAndErrors.$1!.output, OutputMode.plain);
      expect(parseWorkflow("clean_flutter: true").$1!.output, OutputMode.auto);
    });

    test('the --bp-output flag overrides the output of the workflow and is not passed down', () async {
      var configAndErrors = await BPConfig.readPubspec(["--bp-output=json", "--release"], "test/sample/valid_all_options.yaml");
      expect(configAndErrors.$1!.output, OutputMode.json);
      expect(configAndErrors.$1!.cmdArgs, ["--release"]);
    });

    test('an invalid --bp-output value is an error', () async {
      var configAndErrors = await BPConfig.readPubspec(["--bp-output=xml"], "test/sample/valid_all_options.yaml");
      expect(configAndErrors.$1, isNull);
      expect(configAndErrors.$2.single.errorCase, BPConfigValidationErrorCase.invalidOutput);
    });

    test('an invalid output in the workflow is an error', () {
      var configAndErrors = parseWorkflow("output: xml");
      expect(configAndErrors.$1, isNull);
      expect(configAndErrors.$2.single.errorCase, BPConfigValidationErrorCase.invalidOutput);
      expect(configAndErrors.$2.single.message, contains("auto, interactive, plain, verbose, json"));
    });

    test('print_stdout has no effect, and is warned about with a link to the migration guide', () {
      var withPrintStdout = parseWorkflow("print_stdout: true");
      expect(withPrintStdout.$1!.output, OutputMode.auto);
      expect(withPrintStdout.$2.single.errorCase, BPConfigValidationErrorCase.printStdoutReplaced);
      expect(withPrintStdout.$2.single.isWarning, isTrue);
      expect(withPrintStdout.$2.single.message, contains("doc/migration/0_3_to_0_4.md"));

      expect(parseWorkflow("print_stdout: false").$1!.output, OutputMode.auto);
      expect(parseWorkflow("print_stdout: true\noutput: plain").$1!.output, OutputMode.plain);
    });
  });

  group('Hooks', () {
    /// Parses a workflow, enough for the hooks, with a web platform unless [platforms] is given
    (BPConfig?, List<BPConfigValidationError>) parseWorkflow(String yaml, {String platforms = "platforms:\n  web:\n    build:\n      build_command: flutter build web"}) {
      return BPConfig.fromMap(loadYaml("$yaml\n$platforms") as YamlMap, [], "1.0.0", "1", workflowName: "release");
    }

    test('reads the hooks of the workflow and of the platforms', () async {
      BPConfig config = (await BPConfig.readPubspec([], "test/sample/valid_all_options.yaml")).$1!;
      expect([config.buildHooks.pre, config.buildHooks.onSuccess, config.buildHooks.finallyCommand], ["sh ./pre-build.sh", "sh ./post-build.sh", "sh ./cleanup.sh"]);
      expect([config.publishHooks.pre, config.publishHooks.onSuccess, config.publishHooks.finallyCommand], [null, null, "sh ./cleanup-publish.sh"]);

      expect(config.android!.buildHooks.isEmpty, isTrue);

      // The iOS of the sample needs env variables for its publish config, so it is parsed on its own
      BPConfig withIOS = parseWorkflow(
        "clean_flutter: false",
        platforms: [
          "platforms:",
          "  ios:",
          "    build:",
          "      pre_command: sh ./ios-pre.sh",
          "      build_command: flutter build ipa",
          "      post_command:",
          "        on_success: sh ./ios-upload-symbols.sh",
          "        finally: sh ./ios-cleanup.sh",
        ].join("\n"),
      ).$1!;
      PlatformConfig ios = withIOS.ios!;
      expect([ios.buildHooks.pre, ios.buildHooks.onSuccess, ios.buildHooks.finallyCommand], ["sh ./ios-pre.sh", "sh ./ios-upload-symbols.sh", "sh ./ios-cleanup.sh"]);
      expect(ios.publishHooks.isEmpty, isTrue);
    });

    test('rejects the replaced pre_build_command and post_build_command', () {
      var configAndErrors = parseWorkflow("pre_build_command: sh ./pre.sh\npost_build_command: sh ./post.sh");
      expect(configAndErrors.$1, isNull);
      BPConfigValidationError error = configAndErrors.$2.single;
      expect(error.errorCase, BPConfigValidationErrorCase.replacedHookKeys);
      expect(error.message, contains("'release'"));
      expect(error.message, contains("'pre_build_command' is replaced by 'pre_platform_run.build'"));
      expect(error.message, contains("'post_build_command' is replaced by 'post_platform_run.build.on_success'"));
      expect(error.message, contains("doc/migration/0_3_to_0_4.md"));

      expect(parseWorkflow("post_build_command: sh ./post.sh\npost_platform_run:\n  build:\n    finally: sh ./post.sh").$1, isNull, reason: "the old keys are rejected even next to the new ones");
    });

    test('rejects the mistakes in the hooks of a workflow', () {
      Map<String, String> mistakes = {
        "post_platform_run:\n  build:\n    on_succes: sh ./post.sh": "unknown key 'on_succes'",
        "pre_platform_run:\n  deploy: sh ./pre.sh": "unknown key 'deploy'",
        "pre_platform_run: sh ./pre.sh": "'pre_platform_run' must be an object",
        "post_platform_run:\n  build: sh ./post.sh": "'post_platform_run.build' must be an object",
        "post_platform_run:\n  build:\n    finally:": "'post_platform_run.build.finally' must be a command",
        "pre_platform_run:\n  build: ''": "'pre_platform_run.build' must be a command",
      };
      mistakes.forEach((String yaml, String message) {
        var configAndErrors = parseWorkflow(yaml);
        expect(configAndErrors.$1, isNull, reason: yaml);
        expect(configAndErrors.$2.map((BPConfigValidationError e) => e.errorCase), everyElement(BPConfigValidationErrorCase.invalidHook), reason: yaml);
        expect(configAndErrors.$2.map((BPConfigValidationError e) => e.message).join("\n"), contains(message), reason: yaml);
      });
    });

    test('a mistake in the hooks of a platform stops the whole config, not only the platform', () {
      var configAndErrors = parseWorkflow(
        "clean_flutter: false",
        platforms: "platforms:\n  android:\n    build:\n      build_command: flutter build apk\n  web:\n    build:\n      build_command: flutter build web\n      post_command: sh ./post.sh",
      );
      expect(configAndErrors.$1, isNull);
      expect(configAndErrors.$2.single.message, contains("'platforms.web.build.post_command' must be an object"));
    });

    test('runs the platforms in the same order, whatever their order in the pubspec', () async {
      expect(BPConfig.platformOrder.map((TargetPlatform p) => p.name), ["android", "ios", "macos", "windows", "linux", "web"]);

      List<String> platforms = ["web", "linux", "windows", "macos", "ios", "android"];
      BPConfig config = parseWorkflow(
        "clean_flutter: false",
        platforms: ["platforms:", for (String p in platforms) "  $p:\n    build:\n      build_command: flutter build $p"].join("\n"),
      ).$1!;
      expect(config.buildPlatforms, BPConfig.platformOrder);

      BPConfig filtered = (await BPConfig.readPubspec(["--override-target-platforms=web,macos,android"], "test/sample/valid_all_options.yaml")).$1!;
      expect(filtered.buildPlatforms, [TargetPlatform.android, TargetPlatform.macos, TargetPlatform.web]);
    });
  });
}
