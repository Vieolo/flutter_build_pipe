import 'dart:io';

import 'package:build_pipe/utils/config.utils.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:build_pipe/utils/log.utils.dart';
import 'package:path/path.dart' as p;

class WebUtils {
  static Future<void> applyCacheBustPostBuild(BuildConfig config) async {
    List<String> logLines = LogUtils.getActionStartLines("Applying web cache busting for version: ${config.version}");

    print('Applying web cache busting for version: ${config.version}');

    final String buildWebPath = "./build/web";
    (String, String) mainDartJSPattern = (r'main\.dart\.js', "main.dart.js?v=${config.version}");

    // Files to be modified
    // Each file has a list of records, the first item is the regex and the second is the replacement
    final Map<String, List<(String, String)>> filesToPatch = {
      p.join(buildWebPath, 'flutter.js'): [
        mainDartJSPattern,
      ],
      p.join(buildWebPath, 'flutter_bootstrap.js'): [
        mainDartJSPattern,
      ],
      p.join(buildWebPath, 'main.dart.js'): [
        (r'window\.fetch\(a\),', "window.fetch(a + '?v=${config.version}'),"),
      ],
      p.join(buildWebPath, 'index.html'): [
        (r'manifest\.json', 'manifest.json?v=${config.version}'),
        (r'flutter_bootstrap\.js', "flutter_bootstrap.js?v=${config.version}"),
      ],
    };

    // Patching the files
    for (final single in filesToPatch.entries) {
      final file = File(single.key);
      if (await file.exists()) {
        try {
          String content = await file.readAsString();
          List<String> ll = ["\n[file] > ${single.key}"];
          for (var i = 0; i < single.value.length; i++) {
            content = content.replaceAll(
              RegExp(single.value[i].$1, caseSensitive: false),
              single.value[i].$2,
            );
            ll.add("[replacement] > ${single.value[i].$1} to ${single.value[i].$2}");
          }
          await file.writeAsString(content);
          logLines.addAll(ll);
        } catch (e) {
          print(e.toString());
          logLines.add("\n[file] > ${single.key}");
          logLines.add("[error] > ${e.toString()}");
        }
      } else {
        print('File not found: ${p.basename(single.key)}');
        logLines.add("\n[file] > ${single.key}");
        logLines.add("[error] > This file could not be found: ${p.basename(single.key)}");
      }
    }

    Console.logSuccess("√ Web cache busting complete.");
    logLines.addAll(LogUtils.getActionEndLines());
    await LogUtils.appendLogUsingStringList(config, logLines);
  }
}
