import 'dart:io';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/config/platform_specific_config.dart';
import 'package:build_pipe/dx/init_command.dart';
import 'package:build_pipe/runner/output_mode.dart';
import 'package:build_pipe/utils/validation.utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

const String samplePubspec = "name: my_app\nversion: 1.0.0+1\n\n# a comment of the user\ndependencies:\n  path: ^1.9.1\n";

/// Creates a project folder with the [pubspec] and the given folders
Future<Directory> createProject(List<String> folders, {String? pubspec = samplePubspec}) async {
  Directory dir = await Directory.systemTemp.createTemp("build_pipe_init_test");
  addTearDown(() => dir.delete(recursive: true));
  if (pubspec != null) {
    await File(p.join(dir.path, "pubspec.yaml")).writeAsString(pubspec);
  }
  for (String folder in folders) {
    await Directory(p.join(dir.path, folder)).create();
  }
  return dir;
}

/// Parses the default workflow of a pubspec
(BPConfig?, List<BPConfigValidationError>) parseDefault(String pubspec) {
  YamlMap workflow = (loadYaml(pubspec) as YamlMap)["build_pipe"]["workflows"]["default"];
  return BPConfig.fromMap(workflow, [], "1.0.0", "1");
}

/// Uncomments every commented field. The comment above `build_pipe:` is not indented, so it stays
String uncommentAll(String config) {
  return config
      .split("\n")
      .map((String line) {
        RegExpMatch? match = RegExp(r'^(\s+)# (.*)$').firstMatch(line);
        return match == null ? line : "${match.group(1)}${match.group(2)}";
      })
      .join("\n");
}

void main() {
  group('ConfigScaffold', () {
    test('finds the platforms from the folders of the project, in the platform order', () async {
      Directory project = await createProject(["web", "lib", "ios", "android", "test"]);
      expect(ConfigScaffold.detectPlatforms(project.path), [TargetPlatform.android, TargetPlatform.ios, TargetPlatform.web]);
    });

    test('sets up the platforms of the project with the default values, and comments out the rest', () {
      String config = ConfigScaffold.generate(appName: "my_app", platforms: [TargetPlatform.android, TargetPlatform.web]);
      (BPConfig?, List<BPConfigValidationError>) parsed = parseDefault(config);

      expect(parsed.$2, isEmpty);
      BPConfig bp = parsed.$1!;
      expect(bp.buildPlatforms, [TargetPlatform.android, TargetPlatform.web]);
      expect([bp.cleanFlutter, bp.generateLog, bp.output], [true, true, OutputMode.auto]);
      expect(bp.web!.webConfig!.addVersionQueryParam, isTrue);
      expect(bp.web!.buildCommand, "flutter build web");
      expect(bp.android!.buildCommand, "flutter build appbundle");
      expect(bp.buildHooks.isEmpty && bp.android!.buildHooks.isEmpty, isTrue, reason: "the hooks are commented out");
      expect(bp.android!.androidConfig, isNull, reason: "the publish config is commented out");
      expect(bp.xcodeDerivedKey, isNull);
    });

    test('every commented out field is a valid field once uncommented', () {
      String config = uncommentAll(ConfigScaffold.generate(appName: "my_app", platforms: BPConfig.platformOrder));
      (BPConfig?, List<BPConfigValidationError>) parsed = parseDefault(config);

      // The publish config of iOS needs its env variables, which the tests do not have
      expect(parsed.$2.map((BPConfigValidationError e) => e.errorCase), everyElement(BPConfigValidationErrorCase.iosPublishValidation));
      BPConfig bp = parsed.$1!;
      expect(bp.xcodeDerivedKey, "XCODE_DERIVED_PATH");
      expect([bp.buildHooks.pre, bp.buildHooks.onSuccess, bp.buildHooks.finallyCommand], everyElement(isNotNull));
      expect([bp.publishHooks.pre, bp.publishHooks.onSuccess, bp.publishHooks.finallyCommand], everyElement(isNotNull));

      PlatformConfig android = bp.android!;
      expect(android.androidConfig!.publishConfig!.bundleID, "com.example.my_app");
      expect(android.androidConfig!.publishConfig!.releaseTrack, "internal");
      expect([android.buildHooks.pre, android.buildHooks.onSuccess, android.buildHooks.finallyCommand], everyElement(isNotNull));
      expect([android.publishHooks.pre, android.publishHooks.onSuccess, android.publishHooks.finallyCommand], everyElement(isNotNull));
      expect(bp.web!.buildHooks.finallyCommand, "sh ./scripts/web_build_cleanup.sh");
    });

    test('the commented out platforms are valid platforms once uncommented', () {
      String config = uncommentAll(ConfigScaffold.generate(appName: "my_app", platforms: []));
      (BPConfig?, List<BPConfigValidationError>) parsed = parseDefault(config);

      expect(parsed.$2, isEmpty);
      expect(parsed.$1!.buildPlatforms, BPConfig.platformOrder);
    });
  });

  group('InitCommand', () {
    test('adds the config to the end of the pubspec, keeping the rest of it as it is', () async {
      Directory project = await createProject(["android", "web"]);
      (InitResult?, String?) result = await InitCommand.run(project.path, write: true);

      expect(result.$2, isNull);
      expect(result.$1!.platforms, [TargetPlatform.android, TargetPlatform.web]);
      String pubspec = await File(p.join(project.path, "pubspec.yaml")).readAsString();
      expect(pubspec, startsWith(samplePubspec));
      expect(pubspec, endsWith(result.$1!.scaffold));
      expect(pubspec, contains("$samplePubspec\n# build_pipe: "), reason: "an empty line separates the config from the rest");

      (BPConfig?, List<BPConfigValidationError>) config = await BPConfig.readPubspec([], p.join(project.path, "pubspec.yaml"));
      expect(config.$2, isEmpty);
      expect(config.$1!.buildPlatforms, [TargetPlatform.android, TargetPlatform.web]);
    });

    test('separates the config from a pubspec that does not end with a new line', () async {
      Directory project = await createProject(["linux"], pubspec: "name: my_app\nversion: 1.0.0+1");
      expect((await InitCommand.run(project.path, write: true)).$2, isNull);
      String pubspec = await File(p.join(project.path, "pubspec.yaml")).readAsString();
      expect(pubspec, startsWith("name: my_app\nversion: 1.0.0+1\n\n# build_pipe: "));
    });

    test('does not change a pubspec that already has a build_pipe config', () async {
      Directory project = await createProject(["android"]);
      expect((await InitCommand.run(project.path, write: true)).$2, isNull);
      String once = await File(p.join(project.path, "pubspec.yaml")).readAsString();

      (InitResult?, String?) again = await InitCommand.run(project.path, write: true);
      expect(again.$2, contains("already has a build_pipe config"));
      expect(await File(p.join(project.path, "pubspec.yaml")).readAsString(), once);
    });

    test('does not change the pubspec when only asked for the config', () async {
      Directory project = await createProject(["ios"]);
      (InitResult?, String?) result = await InitCommand.run(project.path, write: false);
      expect(result.$1!.scaffold, contains("build_command: flutter build ipa"));
      expect(await File(p.join(project.path, "pubspec.yaml")).readAsString(), samplePubspec);
    });

    test('comments out every platform when the project has no platform folders', () async {
      Directory project = await createProject(["lib"]);
      (InitResult?, String?) result = await InitCommand.run(project.path, write: false);
      expect(result.$2, isNull);
      expect(result.$1!.platforms, isEmpty);
      expect(parseDefault(result.$1!.scaffold).$1!.buildPlatforms, isEmpty);
    });

    test('returns an error for a missing or broken pubspec', () async {
      Directory missing = await createProject([], pubspec: null);
      expect((await InitCommand.run(missing.path, write: true)).$2, contains("pubspec.yaml could not be found"));

      Directory broken = await createProject([], pubspec: "name: [my_app\n");
      expect((await InitCommand.run(broken.path, write: true)).$2, contains("pubspec.yaml could not be read"));
    });
  });
}
