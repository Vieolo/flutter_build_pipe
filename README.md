<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

The pipeline for building & publishing your Flutter app for different target platforms.

## Features

#### General
- Specify platforms, build commands, and your preferences in `pubspec.yaml`
- Logs the output of all build & publish commands for future reviews

#### iOS & macOS
- Publishing the iOS app to App Store
- Optional clearing of XCode's derived data for consistent builds

#### Web
- Adds the version query paramter to build files post-build to solve the caching problem of Flutter web (e.g. `flutter_bootstrap.js?v=0.12.1`)


## Usage
Once the configuration is added to your project, you can run the desired command via:

```bash
# To build for all given platforms
dart run build_pipe:build

# To publish the built app to the given platforms
dart run build_pipe:publish
```

Read the topics below to setup and configure your project. The configuration is quite simple, and you just need to do it once.



## Topics

#### Install & Setup
- [Install & Setup](https://github.com/Vieolo/flutter_build_pipe/blob/master/docs/install/install_intro.md)

#### Platform Specific config and explanations
- [iOS & macOS](https://github.com/Vieolo/flutter_build_pipe/blob/master/docs/apple/apple_intro.md)
- [Web](https://github.com/Vieolo/flutter_build_pipe/blob/master/docs/web/web_intro.md)
- [Android](https://github.com/Vieolo/flutter_build_pipe/blob/master/docs/android/android_intro.md)
- [Windows](https://github.com/Vieolo/flutter_build_pipe/blob/master/docs/windows/windows_intro.md)
- [Linux](https://github.com/Vieolo/flutter_build_pipe/blob/master/docs/linux/linux_intro.md)

#### Misc.
- [Logging](https://github.com/Vieolo/flutter_build_pipe/blob/master/docs/logging/logging_intro.md)
