## 0.3.0

2026-01-15

- Improved the logging to the terminal in both build and publish commands
- For platforms where the publish command is supported, the publish config can be present without the build config

**Breaking changes**: This version introduces two major breaking changes. You can read a migration guide in the docs.

- This version introduces workflows, allowing you to define multiple build or publish workflows in your pubspec and call them using the `dart run build_pipe:<command_name> --workflow=<workflow_name>` command ([#9](https://github.com/Vieolo/flutter_build_pipe/issues/9))
- Each platform now has a separate build and publish config, instead of having the build config directly in the platform object 

## 0.2.7

2025-12-19
- Fixed the error while running processes on windows ([#4](https://github.com/Vieolo/flutter_build_pipe/issues/4))
- Added support for `pre_build_command` which is run before the platform build commands
- Added the ability to funnel the cmd args passed to the `dart run build_pipe:build` command to the platform build commands
- Added support for project version without the `+`

## 0.2.6

2025-12-17
- Improved the error handling while dealing with the log files
- Improved the logging of the build process to the terminal

## 0.2.5

2025-11-11
- Added the publish feature for Android

## 0.2.4

2025-09-15
- Updated the README

## 0.2.3

2025-09-15
- Fixed the doc folder name

## 0.2.2

2025-09-15
- Added the publish feature for iOS
- Restructured the docs

## 0.2.1

2025-09-08
- Fixed the log file on windows

## 0.2.0

2025-08-21

**Breaking change**: The default behavior of web cache busting is changed. Previously, to bust the cache, we used the appliation's version. e.g. `?v=0.12.3`. Now, the default behavior is adding a random hash to bust the cache on every build. You can control the behvavior using the `query_param_versioning_type` field of web.

## 0.1.5

2025-08-16
- Added example
- Adjusted docs
- Confirmed the web caching for `Flutter v3.35.1`

## 0.1.4

2025-07-28
- Fixed the local paths on windows and linux

## 0.1.3

2025-07-17
- Fixed the race condition for logging the web cache bust

## 0.1.2

2025-07-17
- Added the `xcode_derived_data_path_env_key` property to the config which is the name of the environmental variable having the path to XCode derived data as value.
- Improved the printing of the text to the terminal

## 0.1.1

2025-07-13
- Added the `post_build_command` which is a command to be run after all platforms are built

## 0.1.0

2025-07-12
- Initial release
