import 'package:build_pipe/config/config.dart';
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

    test('print_stdout is still read when output is missing, with a warning', () {
      var verbose = parseWorkflow("print_stdout: true");
      expect(verbose.$1!.output, OutputMode.verbose);
      expect(verbose.$2.single.errorCase, BPConfigValidationErrorCase.printStdoutReplaced);
      expect(verbose.$2.single.isWarning, isTrue);

      expect(parseWorkflow("print_stdout: false").$1!.output, OutputMode.auto);
      expect(parseWorkflow("print_stdout: true\noutput: plain").$1!.output, OutputMode.plain);
    });
  });
}
