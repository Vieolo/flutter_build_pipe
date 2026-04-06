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

  test('Should filter platforms using --targets', () async {      
      var singleTarget = await BPConfig.readPubspec(
        ["--targets=android"], 
        "test/sample/valid_all_options.yaml"
      );
      expect(singleTarget.$1, isNotNull);
      expect(singleTarget.$1!.buildPlatforms, hasLength(1));
      expect(singleTarget.$1!.buildPlatforms.first.name, "android");      
      expect(singleTarget.$1!.cmdArgs, isNot(contains("--targets=android")));
      
      var multiTarget = await BPConfig.readPubspec(
        ["--targets=android,web,macos"], 
        "test/sample/valid_all_options.yaml"
      );
      expect(multiTarget.$1, isNotNull);
      expect(multiTarget.$1!.buildPlatforms, hasLength(3));
      final names = multiTarget.$1!.buildPlatforms.map((p) => p.name).toList();
      expect(names, containsAll(["android", "web", "macos"]));

      var capsTarget = await BPConfig.readPubspec(
        ["--targets=ANDROID"], 
        "test/sample/valid_all_options.yaml"
      );
      expect(capsTarget.$1!.buildPlatforms, hasLength(1));
    });

    test('Should return error if filtered targets result in empty list', () async {      
      var errorTarget = await BPConfig.readPubspec(
        ["--targets=nokia_3310"], 
        "test/sample/valid_all_options.yaml"
      );
            
      expect(errorTarget.$1, isNull);
      expect(errorTarget.$2.last.$2, contains("No target platforms were detected"));
    });
}
