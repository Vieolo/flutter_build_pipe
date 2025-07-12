import 'dart:io';

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
  print(config);
}
