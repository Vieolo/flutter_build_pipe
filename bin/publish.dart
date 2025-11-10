import 'package:build_pipe/config/config.dart';

/// https://help.apple.com/asc/appsaltool/#/apdATD1E53-D1E1A1303-D1E53A1126
/// Main entry point of the `dart run build_pipe:publish` command
void main(List<String> args) async {
  // Reading the config
  BPConfig config = await BPConfig.readPubspec();

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
