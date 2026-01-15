import 'package:build_pipe/config/config.dart';
import 'package:test/test.dart';

void main() {
  group('Config Parsing', () {
    test('Should detect the pre-0.3.0 config', () async {
      var configAndErrors = await BPConfig.readPubspec([], "test/sample/pre_0_3_0_config.yaml");
      expect(configAndErrors.$1, isNull);
      expect(configAndErrors.$2, hasLength(4));
      expect(configAndErrors.$2.last.$2, "Please read the migration guide here: https://github.com/vieolo/flutter_build_pipe/blob/master/doc/migration/0_3_0.md");
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
    });

    test('Should detect missing platforms', () async {
      var configAndErrors = await BPConfig.readPubspec([], "test/sample/missing_platforms.yaml");
      expect(configAndErrors.$1, isNull);
      expect(configAndErrors.$2, hasLength(1));

      configAndErrors = await BPConfig.readPubspec(["--workflow=with_empty_build"], "test/sample/missing_platforms.yaml");
      expect(configAndErrors.$1, isNull);
      expect(configAndErrors.$2, hasLength(1));
    });
  });
}
