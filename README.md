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

Build pipeline for building your Flutter app for different target platforms.

## Features

#### General
- Specify platforms, build commands, and your preferences in `pubspec.yaml`
- Logs the output of all build commands for future reviews

#### Web
- Adds the version query paramter to build files post-build to solve the caching problem of Flutter web (e.g. `flutter_bootstrap.js?v=0.12.1`)

## Install & Setup

Add `build_pipe` to your dev dependencies and add configuration to your `pubspec.yaml`. Here is the sample configuration.

```yaml
name: your_project
version: 0.0.1+0000001

dependencies:
    ...

dev_dependencies:
    build_pipe: {latest_version}

flutter:
    ...

# build_pipe configuration
# required
build_pipe:
  # Whether to clean flutter via `flutter clean` before the builds.
  # optional -- default: true
  clean_flutter: true
  # Whether to generate log files
  # optional -- default: true
  generate_log: true
  # Whether to print the output of the commands to the terminal as they are being run
  # optional -- default: false
  print_stdout: false
  # The target platforms you wish to build for
  # required -- At least on platform should be added
  platforms:
    # Read below to know about the common and platform-specific properties of each platform object
    ios:
      build_command: {your build command} # e.g. flutter build ipa
      ... # rest of properties explained below
    android:
      build_command: {your build command} # e.g. flutter build appbundle
      ... # rest of properties explained below
    macos:
      build_command: {your build command} # e.g. flutter build macos
      ... # rest of properties explained below
    windows:
      build_command: {your build command} # e.g. flutter build windows
      ... # rest of properties explained below
    linux:
      build_command: {your build command} # e.g. flutter build linux
      ... # rest of properties explained below
    web:
      build_command: {your build command} # e.g. flutter build web
      ... # rest of properties explained below
```

---
---
You need at least one target platform using their name, as made above. Target platforms has some generic fields which are used by all platforms, such as `build_command` and some platform-specific fields. Here, I explain the common fields first, and then add the platform-specific fields.

```yaml
# These properties are used on each platform
common:
  # Full build command, e.g. flutter build ipa
  # The command is run as you provide it
  # required
  build_command: {your build command}      

# These properties are only applicable to web
web:
    # To solve the caching issue of Flutter web, build_pipe
    # will change the `build/web` files and append query parameters
    # while trying to access the generated static files
    # e.g. `flutter_bootstrap.js?v=0.12.1`
    # This action will be performed after the Flutter's default build
    # optiona -- default: true
    add_version_query_param: true

# These properties are only applicable to iOS
ios:
    # No specific fields yet

# These properties are only applicable to android
android:
    # No specific fields yet

# These properties are only applicable to macos
macos:
    # No specific fields yet

# These properties are only applicable to windows
windows:
    # No specific fields yet

# These properties are only applicable to linux
linux:
    # No specific fields yet
```

## Usage

After configuring your project, to build your project, simply run:
```bash
dart run build_pipe:build
```

## Logging

If `generate_log` field is set to true (default: true), all the commands and actions, along with their output will be recoreded in a log file in `.flutter_build_pipe/logs/{version}/{timestamp}.log`.

If you run `build_pipe:build` with the same version multiple times, the previous logs would not be overwritten and a new one, with the latest timestamp will be created.

Add `.flutter_build_pipe/` to your `.gitignore` for git to ignore this folder.


## Web builds

#### Cache busting
The Flutter web builds, unlike more mature frontend frameworks, do not generate static files with unique URIs. As the result, the Flutter web apps are cached by the browser, practically preventing you from pushing an update to your existing users. You can read more about it [here](https://docs.flutter.dev/platform-integration/web/faq#why-doesnt-my-app-update-immediately-after-its-deployed)

To circumvent this, `build_pipe` will adjust your build files to append a query paramter with your application's version. Our solution is highly inspired by [github.com/doonfrs
flutter-build-web-cache-problem](https://github.com/doonfrs/flutter-build-web-cache-problem).

Please note that our approach is fragile by nature since it depends on the generated Flutter code which may change by a new update. At the time of writing, our code is made for and tested on `Flutter v3.32.5`

You can prevent this by setting the `add_version_query_param` field in your web platform to `false`