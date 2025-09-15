# iOS & macOS intro

- Build
  - [Clearing XCode derived data](#clearing-xcode-derived-data)

- Publish
  - [Configuration to publish to iOS](#configuration-to-publish-to-ios)


## Build

#### Clearing XCode derived data
The derived data of XCode holds some cache of your dependencies and clearing it before the production build, will result in a more consistent output. Note that clearing the derived data will result in a longer build time.

To delete the derived data before the builds, create an environmental variable (name it as you wish, e.g. `XCODE_DERIVED_PATH`) with the path pointing to your derived data location. You can find out the location the derived data in `XCode > Settings > Locations`.

```bash
export XCODE_DERIVED_PATH=/path/to/derived/data
```

Once set, write the name of the env variable in your `build_pipe` config. for example:

```yaml
xcode_derived_data_path_env_key: XCODE_DERIVED_PATH
```

Once passed, the derived data will be erased before a build run.


## Publish

#### Configuration to publish to iOS
To publish your app to iOS, follow these steps. I assume that you already have an Apple developer account and created the initial setup for your app on App Store Connect.

1. Make sure you have XCode and xcrun installed.
2. Create an API key on `App Store Connect` > `Users & Access` > `Integrations` > `Team Keys`. Only proved the `App Manager` access to the key. This should give you a `.p8` file. Do not expose this file and do not add it to version control.
3. Copy the `.p8` file to one of the following places:
    - `/private_keys` -> Root of your project, do not add to git
    - `~/private_keys`
    - `~/.private_keys`
    - `~/.appstoreconnect/private_keys`
4. Add these values to the environmental variables. Since these information are sensitive, `build_pipe` will read the values from your env. You can choose the key as you wish. Here I use an example key and will tell you what value to add:
        keyID: RECHIVE_PUB_KEY_ID
        issuerID: RECHIVE_PUB_ISSUER_ID
        appAppleID: RECHIVE_PUB_APPLE_ID
    - `IOS_APP_KEY_ID` --> The key id of the API key you created. You can find the key ID in the same page you created the API key.
    - `IOS_APP_ISSUER_ID` --> The issuer ID of your account. You can find it on `App Store Connect` > `Users & Access` > `Integrations` > `Team Keys`.
    - `IOS_APP_APPLE_ID` --> The apple ID of your app. You can find the Apple ID your app on `App Store Connect` > `Apps` > `Your App` > `App Information` > `General Information`.
5. Add the publish config to your `pubspec`.

```yaml
build_pipe:
  platforms:
    ios:
      build_command: flutter build ipa
      publish:
        keyID: IOS_APP_KEY_ID # The env variable you created
        issuerID: IOS_APP_ISSUER_ID # The env variable you created
        appAppleID: IOS_APP_APPLE_ID # The env variable you created
        bundleID: com.example.yourapp # The bundle id your app
        outputFilePath: build/ios/ipa/yourapp.ipa # The path to the local output file
```
    
Once you have the API key, added the env variables, and added the publish config, you can just run the publish command. The version of your `pubspec` will be used to send the file to the App Store Connect.

