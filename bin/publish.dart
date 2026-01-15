import 'dart:io';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/utils/console.utils.dart';

/// https://help.apple.com/asc/appsaltool/#/apdATD1E53-D1E1A1303-D1E53A1126
/// Main entry point of the `dart run build_pipe:publish` command
void main(List<String> args) async {
  // Reading the config
  (BPConfig?, List<(Function(String s), String)>) configAndErrors = await BPConfig.readPubspec(args);
  // Printing the errors that were found while parsing the config
  // If the error are fatal the config will be null
  if (configAndErrors.$2.isNotEmpty) {
    for (var error in configAndErrors.$2) {
      error.$1(error.$2);
    }
  }
  BPConfig? config = configAndErrors.$1;
  if (config == null) {
    exit(1);
  }

  if (config.publishPlatforms.isEmpty) {
    Console.logError("No target platforms were detected for publish. Please add your target platforms to pubspec");
    exit(1);
  }

  Console.logInfo("\nStarting the publish process...\n");
  print("The following target platforms are detected:");
  for (var i = 0; i < config.publishPlatforms.length; i++) {
    String prefix = "├──";
    if (i == config.publishPlatforms.length - 1) {
      prefix = "└──";
    }
    print("$prefix ${config.publishPlatforms[i].name}${i == config.publishPlatforms.length - 1 ? "\n" : ""}");
  }

  // -=-=-=-=-=-=
  // iOS
  // -=-=-=-=-=-=
  if (config.ios != null && config.ios!.iosConfig!.publishConfig != null) {
    var iosPub = config.ios!.iosConfig!.publishConfig!;
    await iosPub.uploadToIOS(config: config);
  }

  // -=-=-=-=-=-=
  // Android
  // -=-=-=-=-=-=
  if (config.android != null && config.android!.androidConfig!.publishConfig != null) {
    var androidPub = config.android!.androidConfig!.publishConfig!;
    await androidPub.uploadToPlayStore(config: config);
  }
}
