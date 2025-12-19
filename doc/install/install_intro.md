# Install & Setup
Add `build_pipe` to your dev dependencies and add configuration to your `pubspec.yaml`. 

`build_pipe` object should be at the root level of your `pubspec.yaml` in the same column as the `flutter` object.

Here is the detailed explanation of the configuration.

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
  # The command that will be run before the platforms are built
  # This command will be executed as it's provided
  # Useful for running code generators or other pre-build tasks
  # optional -- default: null
  pre_build_command: your pre-build command # e.g. dart run build_runner build --delete-conflicting-outputs
  # The command that will be run after the all platforms have been
  # built (successfully or not)
  # This command will be executed as it's provided
  # optional -- default: null
  post_build_command: your post-build command # e.g. sh ./post-build.sh
  # The environment variable pointing to the location
  # of the derived data of XCode
  # If provided, the derived data will be erased before iOS or macOS builds
  # optional -- default: null
  xcode_derived_data_path_env_key: YOUR_ENV_VAR_KEY_TO_XCODE
  # The target platforms you wish to build for
  # required -- At least on platform should be added
  platforms:
    # Read below to know about the common and platform-specific properties of each platform object
    ios:
      build_command: your build command # e.g. flutter build ipa
      ... # rest of properties explained below
    android:
      build_command: your build command # e.g. flutter build appbundle
      ... # rest of properties explained below
    macos:
      build_command: your build command # e.g. flutter build macos
      ... # rest of properties explained below
    windows:
      build_command: your build command # e.g. flutter build windows
      ... # rest of properties explained below
    linux:
      build_command: your build command # e.g. flutter build linux
      ... # rest of properties explained below
    web:
      build_command: your build command # e.g. flutter build web
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
  build_command: your build command      

# These properties are only applicable to web
web:
    # To solve the caching issue of Flutter web, build_pipe
    # will change the `build/web` files and append query parameters
    # while trying to access the generated static files
    # e.g. `flutter_bootstrap.js?v=0.12.1`
    # This action will be performed after the Flutter's default build
    # optional -- default: true
    add_version_query_param: true
    
    # This field determines the type of text to be used as
    # the query param to bust the cache
    # There are two options: `hash` and `semver`
    #
    # If hash, a random hash is used which will bust the cache
    # on every build. e.g. `?v=1kjdghsflkdh`
    #
    # If semver, the version of your application is used. This means
    # that unless you increment the version, the cache
    # won't be bust. e.g. `?v=0.12.3`
    #
    # optional -- default: hash
    query_param_versioning_type: hash

# These properties are only applicable to iOS
ios:
    # The publish object provides the iOS-specific
    # configuration to publish the built iOS app to
    # the app store.
    #
    # This object is optional but if provided, all of
    # its fields are required
    #
    # To learn how to setup the iOS publish, have a
    # look at the iOS doc
    #
    # optional
    publish:
        # The env variable holding the App Store Key ID
        #
        # Required
        keyID: YOUR_APP_KEY_ID
        # The env variable holding the App Store Issuer ID
        #
        # Required
        issuerID: YOUR_APP_ISSUER_ID
        # The env variable holding your app's Apple ID
        #
        # Required
        appAppleID: YOUR_APP_APPLE_ID
        # The bundle id of your app, used in App Store Connect
        #
        # Required
        bundleID: com.example.yourapp
        # The path to the local build file
        #
        # Required
        outputFilePath: build/ios/ipa/yourapp.ipa

# These properties are only applicable to android
android:
    # The publish object provides the Android-specific
    # configuration to publish the built Android app to
    # the Play Store.
    #
    # This object is optional but if provided, most of
    # its fields are required
    #
    # To learn how to setup the Android publish, have a
    # look at the Android doc
    #
    # optional
    publish:
        # The bundle id or package name of your app, used in Play Store
        #
        # Required
        bundleID: com.example.yourapp
        # The path to the local build file
        #
        # Required
        outputFilePath: build/app/outputs/bundle/release/app-release.aab
        # The type of the release to be made. The options are `internal`,
        # `alpha`, `beta`, and `production`
        #
        # Required
        releaseTrack: internal
        # The env variable holding the path to the JSON key of the Play
        # Store API. If not provided, the default path will be looked up.
        # The default path is -> `./private_keys/play_api_key.json` (in the project root)
        #
        # Optional
        credentialPath: PLAY_API_KEY_PATH # optional env variabl key

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