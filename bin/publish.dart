import 'dart:convert';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:build_pipe/utils/process.utils.dart';

/// https://help.apple.com/asc/appsaltool/#/apdATD1E53-D1E1A1303-D1E53A1126
/// Main entry point of the `dart run build_pipe:publish` command
void main(List<String> args) async {
  BPConfig config = await BPConfig.readPubspec();

  if (config.ios != null && config.ios!.iosPublishConfig != null) {
    var iosPub = config.ios!.iosPublishConfig!;
    var iosOut = await ProcessHelper.runCommandUsingConfig(
      startMessage: "Starting to publish the iOS app...",
      errorMessage: "There was a problem in publishing the iOS app",
      successMessage: "√ iOS app is successfully published",
      executable: "xcrun",
      exitIfError: false,
      redactions: [
        iosPub.appAppleID,
        iosPub.issuerID,
        iosPub.keyID,
      ],
      arguments: [
        "altool",
        "--upload-package",
        iosPub.outputFilePath,
        "-t",
        'ios',
        "--apple-id",
        iosPub.appAppleID,
        "--bundle-id",
        '"${iosPub.bundleID}"',
        "--apiKey",
        iosPub.keyID,
        "--apiIssuer",
        iosPub.issuerID,
        "--bundle-short-version-string",
        config.version,
        "--bundle-version",
        config.buildVersion,
        "--asc-public-id",
        iosPub.issuerID,
        "--output-format",
        "json",
      ],
      config: config,
    );

    if (iosOut.$1 != 0 && iosOut.$2.isNotEmpty) {
      try {
        Map<String, dynamic> iosErr = jsonDecode(iosOut.$2[0]);
        if (iosErr.containsKey("product-errors")) {
          List<dynamic> peList = iosErr["product-errors"];
          for (var pe in peList) {
            Console.logError("-- ${pe["userInfo"]["NSLocalizedFailureReason"] ?? "-"}\n");
          }
        }
      } catch (_) {}
    }
  }
}
