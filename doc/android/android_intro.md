# Android

- [Android](#android)
  - [Build](#build)
  - [Publish](#publish)
      - [Setting up the Play Store API](#setting-up-the-play-store-api)
      - [Placement of JSON key](#placement-of-json-key)
      - [Publish configuration](#publish-configuration)


## Build
Android build is supported via the `pubspec` config. At this time, only the `build_command` is supported for the build process.



## Publish

#### Setting up the Play Store API

To setup the publish capabilities for Android, you need to follow these steps:

1. Create a Google Cloud Platform (GCP) account if you don't have one.
2. Create or select the project related to your app.
3. Enable the [Google Play Android Developer API](https://console.cloud.google.com/apis/api/androidpublisher.googleapis.com/) for your project, if not enabled already
4. Create a service account by visiting `IAM & Admin` > `Service Accounts` > `Create Service Account` in the Google Cloud Platform. You only need to proved a name and an ID for the service account. After successful creation, you will have an email ID for the service account.
5. Create a JSON API key for the newly created service account by opening the details of the service account and visiting the `Keys` section. After creating the JSON key, it will be automatically downloaded.
6. Place the key in the project. In the next section, I'll discuss the options.
7. Move to the Play Store
8. Start inviting a new user in the `Users and Permissions` section.
9. The invite form will ask for an email address. Paste the email address of the service account you created in GCP
10. In the `App permissions` tab of the form, select your app
11. In the `Account permissions` tab of the form, select the minimum required permission. For releasing the app, you would only need the permissions in the `Releases` section.
12. Click on `Invite user` button. You should now see the service account added to the list of the users with an active status.

#### Placement of JSON key
After downloading the JSON API key from GCP, you have two option:
1. Rename the file to `play_api_key.json` and place it in `private_keys` folder in the root of the flutter project. In this approach, you don't need to add anything to the pubspec config. Make sure that you add the key (or preferably the `private_keys` folder) to `.gitignore`.
2. You place the key anywhere you want, create an environment variable holding the path to the key, and add the env variable key to the `credentialPath` field of the publish config.

#### Publish configuration

Here is a sample of the publish config for Android:

```yaml
build_pipe:
 platforms:
    android:
      build_command: flutter build appbundle
      publish:
        outputFilePath: build/app/outputs/bundle/release/app-release.aab
        bundleID: com.example.yourapp
        releaseTrack: internal
        credentialPath: PLAY_API_KEY_PATH # optional env variabl key
```

Here is a brief explanation for the fields:
- `outputFilePath` -> The path to the artifact made with the Flutter's build command. This file will be uploaded to the Play Store
- `bundleID` -> The bundle ID or package name of the app. e.g., com.example.yourapp
- `releaseTrack` -> This determines which type of release should be made while uploading the new build. The options are: `internal`, `alpha`, `beta`, and `production`. It is recommended to use a testing track, test the application, and then promote the release to production.
- `credentialPath` -> Optional field, holding the environmental variable, pointing to the JSON key for the Play Store API