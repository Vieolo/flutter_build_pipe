# Run order & hooks

The `build` and `publish` commands run their steps in a fixed order, and you can hook your own commands around the whole run and around each platform.

## Run order

Both commands run in three parts:

1. **Before the platforms**
   - `build` only: deleting the XCode derived data (when `xcode_derived_data_path_env_key` is set), then `flutter clean` and `flutter pub get` (when `clean_flutter` is true)
   - `pre_platform_run` of the command
2. **The platforms**, always in this order, regardless of their order in the pubspec or in `--override-target-platforms`:
   Android, iOS, macOS, Windows, Linux, and Web. Each platform runs:
   - its `pre_command`
   - its build or publish command
   - its extra steps, such as the cache bust of web
   - its `post_command.on_success`
   - its `post_command.finally`
3. **After the platforms**
   - `post_platform_run.on_success` of the command
   - `post_platform_run.finally` of the command

## Hooks

The hooks of the whole run are set in the workflow, separately for the `build` and `publish` commands:

```yaml
build_pipe:
  workflows:
    default:
      # optional
      pre_platform_run:
        build: dart run build_runner build --delete-conflicting-outputs
        publish: sh ./scripts/check_release_notes.sh
      # optional
      post_platform_run:
        build:
          on_success: sh ./scripts/tag_release.sh
          finally: sh ./scripts/build_cleanup.sh
        publish:
          on_success: sh ./scripts/announce_release.sh
          finally: sh ./scripts/publish_cleanup.sh
```

The hooks of a platform are set in its `build` or `publish`:

```yaml
      platforms:
        ios:
          build:
            pre_command: sh ./scripts/install_certificates.sh
            build_command: flutter build ipa
            post_command:
              on_success: sh ./scripts/upload_symbols.sh
              finally: sh ./scripts/remove_certificates.sh
          publish:
            ...
            pre_command: ...
            post_command:
              on_success: ...
              finally: ...
```

Every hook is optional. A hook is a single command, run as you provide it, like `build_command`. A mistake in the hooks, such as an unknown key or an empty command, stops the command before anything runs, since running the wrong hook, or none, can have unintended consequences.

## When a step fails

- When anything before the platforms fails, no platform runs
- When the `pre_command` of a platform fails, its build or upload, its extra steps, and its `on_success` are skipped
- When the build or the upload of a platform fails, its extra steps and its `on_success` are skipped
- The platforms are independent, so a failed platform does not stop the others
- `on_success` runs only when nothing before it has failed: in a platform, nothing of that platform, and after the platforms, nothing in the whole run
- `finally` runs whether anything before it has failed or not, as long as its part of the run has started. The `finally` of a platform runs once the platform has started, and the `finally` of `post_platform_run` runs in every run
- A failed `finally` is a failure too, and the platform it belongs to has failed

The command exits with the code `1` if any step has failed, and `0` otherwise.

`finally` does not run when the run is stopped from outside, e.g. with Ctrl+C or when a CI job is cancelled.

## Env variables

The hooks get the env variables of build_pipe, along with these:

| Variable | Given to | Value |
| --- | --- | --- |
| `BUILD_PIPE_COMMAND` | all hooks | `build` or `publish` |
| `BUILD_PIPE_WORKFLOW` | all hooks | The name of the workflow, e.g. `default` |
| `BUILD_PIPE_VERSION` | all hooks | The version of the app, e.g. `1.2.0+12` |
| `BUILD_PIPE_PLATFORM` | the hooks of a platform | `android`, `ios`, `macos`, `windows`, `linux`, or `web` |
| `BUILD_PIPE_STATUS` | `finally` | `failed` if anything before it has failed (in the platform, or in the run for `post_platform_run`), otherwise `succeeded` |
| `BUILD_PIPE_SUCCEEDED_PLATFORMS` | `post_platform_run` | The platforms that have succeeded, separated by commas, e.g. `android,web` |
| `BUILD_PIPE_FAILED_PLATFORMS` | `post_platform_run` | The platforms that have failed |
| `BUILD_PIPE_SKIPPED_PLATFORMS` | `post_platform_run` | The platforms that have not run, since something before them has failed |

For example, a `finally` that publishes whatever has been built, even when some platforms have failed:

```sh
#!/bin/sh
for platform in $(echo "$BUILD_PIPE_SUCCEEDED_PLATFORMS" | tr ',' ' '); do
  sh ./scripts/upload_artifact.sh "$platform"
done
```

## In the terminal

A platform with hooks or extra steps is shown with its steps under it:

```
Pre-build
├── √ flutter clean        1.1s
├── √ flutter pub get      2.0s
└── √ Pre-platform run     9.4s
Build
├── √ Android             2m 7s
└── X iOS                 1m 3s  Build has failed
    ├── √ Pre command      0.8s
    ├── X Build           1m 2s  exited with code 65
    ├── - On success             skipped, Build has failed
    └── √ Finally          0.3s
Post-build
├── - On success                 skipped, an earlier step has failed
└── √ Finally              0.2s
```
