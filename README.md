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

## Why this project exists
`flutter_build_pipe` aims to be a pure-dart tool for building and releasing Flutter applications with minimal setup and first-party support for Flutter's components and occasional shortcomings.

## Features

#### General
- Specify platforms, build commands, and your preferences in `pubspec.yaml`
- Logs the output of all build & publish commands for future reviews
- Define multiple workflows for different build, environment, etc.
- Hook your own commands before and after the whole run and each platform, with `on_success` and `finally` hooks
- Shows the run as a live tree in the terminal, line by line in CI, or as JSON for scripts and agents
- Exits with the code `1` when any step fails, so a CI stops at a failed build

#### iOS & macOS
- Publishing the iOS app to App Store
- Optional clearing of XCode's derived data for consistent builds

#### Android
- Publishing the Android app to the Play Store

#### Web
- Adds the version query parameter to build files post-build to solve the caching problem of Flutter web (e.g. `flutter_bootstrap.js?v=0.12.1`)


## Installation
Add `build_pipe` to your dev dependencies, and generate a starting config in your `pubspec.yaml`:

```bash
dart pub add --dev build_pipe

# Adds a `default` workflow to the end of pubspec.yaml, with every field of the config.
# The platforms with a folder in your project are set up, and the rest is commented out
dart run build_pipe:init
```


## Usage
Once the configuration is added to your project, `flutter_build_pipe` offers you two commands:

```bash
##### BUILD #####
# To build for all given platforms in the default workflow
dart run build_pipe:build

##### PUBLISH #####
# To publish the built app to the given platforms in the default workflow
dart run build_pipe:publish
```

Both commands support these flags:

```bash
# To build for all given platforms in a named workflow. If omitted, the `default`
# workflow is run
--workflow=your_workflow_name

# To use only one (or more) of the platforms defined in a workflow (comma-separated),
# ignoring the other platforms. It's useful to run the build/publish of a single platform
# that failed in the previous runs. If omitted, all platforms of the workflow is used
--override-target-platforms=android
--override-target-platforms=android,ios,web

# To choose how the run is shown, overriding the `output` field of the workflow
# The values are: auto | interactive | plain | verbose | json
# If omitted, the output field of the config is used. If both the flag and the config
# fields are absent, the default value of `auto` is used
--bp-output=plain

# To see the options of a command
--help

# Example
dart run build_pipe:build --workflow=your_workflow_name --override-target-platforms=android --bp-output=json
```

Besides the above known flags, any other args given will pass down to the build command of a platform
```bash
# The build command will funnel all other args passed (e.g., --dart-define) to the build
# commands on all platforms
# This allows github actions etc to pass environment vars down to the build cmd without editing the yaml file
dart run build_pipe:build --dart-define=ENVIRONMENT=prod

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
- [Output & JSON](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/output/output_intro.md)
- [Run order & hooks](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/hooks/hooks_intro.md)

#### Migration
- [Migration from 0.3 to >= 0.4](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/migration/0_3_to_0_4.md)
- [Migration from < 0.3.0](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/migration/0_3_0.md)

