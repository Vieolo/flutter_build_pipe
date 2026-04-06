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

[![pub package](https://img.shields.io/pub/v/build_pipe.svg)](https://pub.dev/packages/build_pipe)
[![publisher](https://img.shields.io/badge/publisher-vieolo.com-blue.svg)](https://pub.dev/publishers/vieolo.com)
[![likes](https://img.shields.io/pub/likes/build_pipe)](https://pub.dev/packages/build_pipe/score)
[![dm](https://img.shields.io/pub/dm/build_pipe)](https://pub.dev/packages/build_pipe/score)
![GitHub Repo stars](https://img.shields.io/github/stars/vieolo/flutter_build_pipe)

The pipeline for building & publishing your Flutter app for different target platforms.

## Features

#### General
- Specify platforms, build commands, and your preferences in `pubspec.yaml`
- Logs the output of all build & publish commands for future reviews
- Define multiple workflows for different build, environment, etc.

#### iOS & macOS
- Publishing the iOS app to App Store
- Optional clearing of XCode's derived data for consistent builds

#### Android
- Publishing the Android app to the Play Store

#### Web
- Adds the version query paramter to build files post-build to solve the caching problem of Flutter web (e.g. `flutter_bootstrap.js?v=0.12.1`)


## Usage
Once the configuration is added to your project, you can run the desired command via:

```bash
##### BUILD #####

# To build for all given platforms in the default workflow
dart run build_pipe:build

# To build for all given platforms in a named workflow
dart run build_pipe:build --workflow=your_workflow_name

# To use one (or more) of the platforms defined in a workflow (comma-separated)
dart run build_pipe:build --override-target-platforms=android,ios,web

# The build command will funnel all other args passed (e.g., --dart-define) to the build
# commands on all platforms
# This allows github actions etc to pass environment vars down to the build cmd without editing the yaml file
dart run build_pipe:build --dart-define=ENVIRONMENT=prod

##### PUBLISH #####

# To publish the built app to the given platforms in the default workflow
dart run build_pipe:publish

# To publsih the built app for all given platforms in a named workflow
dart run build_pipe:publish --workflow=your_workflow_name

# To use one (or more) of the platforms defined in a workflow (comma-separated)
dart run build_pipe:publish --override-target-platforms=android


```

Read the topics below to setup and configure your project. The configuration is quite simple, and you just need to do it once.


## Topics

#### Install & Setup
- [Install & Setup](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/install/install_intro.md)

#### Platform Specific config and explanations
- [iOS & macOS](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/apple/apple_intro.md)
- [Web](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/web/web_intro.md)
- [Android](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/android/android_intro.md)
- [Windows](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/windows/windows_intro.md)
- [Linux](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/linux/linux_intro.md)

#### Misc.
- [Logging](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/logging/logging_intro.md)

#### Migration
- [Migration from < 0.3.0](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/migration/0_3_0.md)

