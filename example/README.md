# `build_pipe` example pubspec config

This example has every field of the config, so you can copy it and remove the fields you don't need. Only `workflows`, a workflow, `platforms`, the `build_command` of each platform you build, and the fields of a `publish` you keep (except `credentialPath` and the hooks) are required. The hooks of `publish` are only for iOS and Android, the platforms that can be published at the moment. Read what each field does in the [install doc](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/install/install_intro.md), and about the hooks in the [run order & hooks doc](https://github.com/Vieolo/flutter_build_pipe/blob/master/doc/hooks/hooks_intro.md).

```yaml
name: your_project
version: 0.0.1+0000001

dependencies:
    ...

dev_dependencies:
    build_pipe: {latest_version}

flutter:
    ...


build_pipe:
  workflows:
    # Run when no `--workflow` is given. Add as many workflows as you need, each with the same fields
    default:
      clean_flutter: true
      generate_log: true
      output: auto # auto | interactive | plain | verbose | json
      xcode_derived_data_path_env_key: PATH_TO_XCODE_DERIVED # the env variable key
      pre_platform_run:
        build: dart run build_runner build --delete-conflicting-outputs
        publish: sh ./scripts/pre_publish.sh
      post_platform_run:
        build:
          on_success: sh ./scripts/post_build.sh
          finally: sh ./scripts/build_cleanup.sh
        publish:
          on_success: sh ./scripts/post_publish.sh
          finally: sh ./scripts/publish_cleanup.sh
      # The platforms always run in the order android, ios, macos, windows, linux, web
      platforms:
        android:
          build:
            pre_command: sh ./scripts/android_pre_build.sh
            build_command: flutter build appbundle
            post_command:
              on_success: sh ./scripts/android_post_build.sh
              finally: sh ./scripts/android_build_cleanup.sh
          publish:
            outputFilePath: build/app/outputs/bundle/release/app-release.aab
            bundleID: com.example.yourapp
            releaseTrack: internal # internal | alpha | beta | production
            credentialPath: PLAY_API_KEY_PATH # optional env variable key
            pre_command: sh ./scripts/android_pre_publish.sh
            post_command:
              on_success: sh ./scripts/android_post_publish.sh
              finally: sh ./scripts/android_publish_cleanup.sh
        ios:
          build:
            pre_command: sh ./scripts/ios_pre_build.sh
            build_command: flutter build ipa
            post_command:
              on_success: sh ./scripts/ios_post_build.sh
              finally: sh ./scripts/ios_build_cleanup.sh
          publish:
            keyID: IOS_APP_KEY_ID # the env variable key
            issuerID: IOS_APP_ISSUER_ID # the env variable key
            appAppleID: IOS_APP_APPLE_ID # the env variable key
            bundleID: com.example.yourapp
            outputFilePath: build/ios/ipa/yourapp.ipa
            pre_command: sh ./scripts/ios_pre_publish.sh
            post_command:
              on_success: sh ./scripts/ios_post_publish.sh
              finally: sh ./scripts/ios_publish_cleanup.sh
        macos:
          build:
            pre_command: sh ./scripts/macos_pre_build.sh
            build_command: flutter build macos
            post_command:
              on_success: sh ./scripts/macos_post_build.sh
              finally: sh ./scripts/macos_build_cleanup.sh
        windows:
          build:
            pre_command: sh ./scripts/windows_pre_build.sh
            build_command: flutter build windows
            post_command:
              on_success: sh ./scripts/windows_post_build.sh
              finally: sh ./scripts/windows_build_cleanup.sh
        linux:
          build:
            pre_command: sh ./scripts/linux_pre_build.sh
            build_command: flutter build linux
            post_command:
              on_success: sh ./scripts/linux_post_build.sh
              finally: sh ./scripts/linux_build_cleanup.sh
        web:
          build:
            pre_command: sh ./scripts/web_pre_build.sh
            build_command: flutter build web
            add_version_query_param: true
            query_param_versioning_type: hash # hash | semver
            post_command:
              on_success: sh ./scripts/web_post_build.sh
              finally: sh ./scripts/web_build_cleanup.sh
```
