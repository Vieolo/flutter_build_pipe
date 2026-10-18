## 0.4.0

2026-10-18
- Redesigned the terminal output
- Added the `output` field to the workflows, with the values `auto`, `interactive`, `plain`, `verbose`, and `json`. `json` writes the run as JSON Lines, for scripts and agents.
- Added the `--bp-output` CLI option to both commands, which overrides the `output` of the workflow without changing the config
- With `output: auto`, a set `CI` env variable now counts as no terminal, so the steps are printed line by line in a CI
- The messages printed outside of a run, such as the errors of the config, no longer contain color codes when the output is not a terminal
- The redacted values, such as the App Store Connect keys, are now replaced line by line, so a value split between two chunks of the output is no longer missed
- Fixed the crash of the `publish` command when the iOS or Android platform of a workflow has a build config but no publish config
- A missing executable, or a failed authentication with the Play Store API, now fails its step instead of crashing the command
- An invalid UTF-8 character in the output of a command no longer crashes the command
- Closing the output early, e.g. by piping it to `head`, no longer crashes the run. The run finishes, and the log file still has all of it
- Added hooks around the build and the publish of each platform: `pre_command`, and `post_command` with `on_success` and `finally`
- Added `pre_platform_run` and `post_platform_run` to the workflows, with separate hooks for the `build` and `publish` commands. `on_success` runs only when nothing has failed, and `finally` runs whether anything has failed or not
- The hooks get env variables describing the run, such as the platform, the status, and the platforms that have succeeded or failed
- A mistake in the hooks, such as an unknown key or an empty command, stops the command before anything runs

**Breaking changes**:

- The minimum Dart SDK version is now 3.10.7
- The `build` and `publish` commands now exit with the code `1` when any step fails. Previously, a failed platform build or store upload still exited with the code `0`
- The log file has a new format, with one numbered section per step and a summary of the run at the end
- `pre_build_command` and `post_build_command` are replaced by `pre_platform_run.build` and `post_platform_run.build`. The old keys are no longer read, and a workflow using them stops with an error
- The platforms now always run in the order Android, iOS, macOS, Windows, Linux, and Web, for both `build` and `publish`. Previously, iOS ran first
- `print_stdout` field is replaced by `output`. It is no longer read and has no effect, and a warning pointing to the migration guide is shown while it is in the config. `print_stdout: true` is now `output: verbose`

## 0.3.2

2026-04-06
- Added the ability to select one (or more) target platform of a workflow by passing the `--override-target-platforms` CLI option
- Added the much overdue `--help` flag for all commands
- Fixed a bug in the validation of the publish config of the iOS apps

## 0.3.1

2026-01-21
- Fixed the error where a build command would result in buffer overflow, commonly seen while building macOS apps

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
