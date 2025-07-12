import 'dart:io';

import 'package:build_pipe/utils/builder.utils.dart';
import 'package:build_pipe/utils/config.utils.dart';
import 'package:yaml/yaml.dart' as yaml;

void main(List<String> args) async {
  final rawPubspecFile = File('pubspec.yaml');
  if (!(await rawPubspecFile.exists())) {
    print("pubspec.yaml file could not be found!");
    return;
  }

  final pubspec = yaml.loadYaml(await rawPubspecFile.readAsString());
  if (!(pubspec as yaml.YamlMap).containsKey("build_pipe")) {
    print("please add the build_pipe configuration to your pubspec file!");
    return;
  }

  final config = BuildConfig.fromMap(pubspec["build_pipe"]);
  if (config.platforms.isEmpty) {
    print("No target platforms were detected. Please add your target platforms to pubspec");
    return;
  }

  print("\nStarting the build process...\n");
  print("The following target platforms are detected:");
  print("${config.platforms.map((z) => z.name).join(", ")}\n");

  if (config.cleanFlutter) {
    print("Cleaning flutter existing builds...");
    await Process.run("flutter", ["clean"]);
    print("√ Flutter cleaned");
    print("Getting pub packages");
    await Process.run("flutter", ["pub", "get"]);
    print("√ Flutter pub packages synced");
  }

  PipeBuilder.buildAll(config);
}
