import 'dart:io';
import 'dart:convert';

import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/config/web_specific_config.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// The utility class for handling web specific functionalities
class WebUtils {
  /// Gets the path of a given file in the `build` folder
  static String _getFilePath(String fp) {
    return p.join(Directory.current.path, "build", "web", fp);
  }

  /// This function modifies the build output of the Flutter web
  ///
  /// Flutter has no built-in method to bust certain caches, so, this function will
  /// add the version number to some paths. e.g. `main.dart.js?v=0.12.3`
  ///
  /// By adding the version number, the browser will re-fetch the files again
  ///
  /// It is run as a part of the web build step, so it reports through the [context] of that step
  static Future<StepError?> applyCacheBustPostBuild(BPConfig config, StepContext context) async {
    WebVersioningType versioningType = config.web?.webConfig?.webVersioningType ?? WebVersioningType.hash;
    context.status(versioningType.isHash ? "Applying web cache bust" : "Applying web cache bust for version: ${config.version}");

    String vValue = versioningType.isHash ? md5.convert(utf8.encode(DateTime.now().toIso8601String())).toString() : config.version;

    (String, String) mainDartJSPattern = (
      r'main\.dart\.js',
      "main.dart.js?v=$vValue",
    );

    // Files to be modified
    // Each file has a list of records, the first item is the regex and the second is the replacement
    final Map<String, List<(String, String)>> filesToPatch = {
      WebUtils._getFilePath('flutter.js'): [
        mainDartJSPattern,
      ],
      WebUtils._getFilePath('flutter_bootstrap.js'): [
        mainDartJSPattern,
      ],
      WebUtils._getFilePath('main.dart.js'): [
        (r'window\.fetch\(a\),', "window.fetch(a + '?v=$vValue'),"),
      ],
      WebUtils._getFilePath('index.html'): [
        (r'manifest\.json', 'manifest.json?v=$vValue'),
        (r'flutter_bootstrap\.js', "flutter_bootstrap.js?v=$vValue"),
      ],
    };

    // Patching the files
    for (final single in filesToPatch.entries) {
      final file = File(single.key);
      if (await file.exists()) {
        try {
          String content = await file.readAsString();
          context.log("[file] > ${single.key}");
          for (var i = 0; i < single.value.length; i++) {
            content = content.replaceAll(
              RegExp(single.value[i].$1, caseSensitive: false),
              single.value[i].$2,
            );
            context.log("[replacement] > ${single.value[i].$1} to ${single.value[i].$2}");
          }
          await file.writeAsString(content);
        } catch (e) {
          context.warn("The cache bust could not be applied to ${p.basename(single.key)} -> ${e.toString()}");
        }
      } else {
        context.warn("The cache bust is not applied to ${p.basename(single.key)}, since the file could not be found");
      }
    }

    return null;
  }
}
