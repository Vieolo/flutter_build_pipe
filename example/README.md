# `build_pipe` example pubspec config

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
  clean_flutter: true
  generate_log: true
  print_stdout: false
  pre_build_command: "sh ./pre-build.sh"
  post_build_command: "sh ./post-build.sh"
  xcode_derived_data_path_env_key: PATH_TO_XCODE_DERIVED # the env variable key
  platforms:
    ios:
      build_command: flutter build ipa
      publish:
        keyID: IOS_APP_KEY_ID # the env variable key
        issuerID: IOS_APP_ISSUER_ID # the env variable key
        appAppleID: IOS_APP_APPLE_ID # the env variable key
        bundleID: com.example.yourapp
        outputFilePath: build/ios/ipa/yourapp.ipa
    android:
      build_command: flutter build appbundle
      publish:
        outputFilePath: build/app/outputs/bundle/release/app-release.aab
        bundleID: com.example.yourapp
        releaseTrack: internal
        credentialPath: PLAY_API_KEY_PATH # optional env variabl key
    macos:
      build_command: flutter build macos
    windows:
      build_command: flutter build windows
    linux:
      build_command: flutter build linux
    web:
      build_command: flutter build web
      add_version_query_param: true
      query_param_versioning_type: hash
```