# CameraTest

![CI](https://github.com/espresso3389/CameraTest/workflows/CI/badge.svg)

The purpose of the project is to evaluate the video recording quality of various phone cameras.

# Building

## Secrets

Automated build on GitHub Actions heavily depends on Secrets and you should set the following secrets to build the app correctly:

### Android

Name               | Description
-------------------|------------------------
`ANDROID_APP_ID`                    | Application ID for Android such as `com.example.app`; the application ID in build.gradle will be overwritten by the value.
`ANDROID_KEYSTORE_BASE64`           | BASE64 encoded keystore file.
`ANDROID_KEYSTORE_PASSWORD`         | Password for the keystore file.
`ANDROID_KEY_ALIAS`                 | Key alias in the keystore file.
`ANDROID_KEY_PASSWORD`              | Password for the key.
`ANDROID_SERVICEACCOUNT_JSON_BASE64`| JSON file that describes service account to upload appbundle to Google Play.
`ANDROID_UPLOAD_TRACK`              | Upload destination track. For internal testing, it is `internal`.

### iOS

Name               | Description
-------------------|------------------------
`IOS_BUNDLE_ID`                   | Bundle ID such as `com.example.app`; the bundle ID in project files will be overwritten by the value.
`IOS_TEAM_ID`                     | Development Team ID; the team ID in project files will be overwritten by the value.
`IOS_APPLE_DIST_P12_BASE64`       | BASE64 encoded signing certificate in P12 form.
`IOS_APPLE_DIST_P12_PASSWORD`     | Password for the signing certificate
`IOS_PROVISIONING_PROFILE_BASE64` | BASE64 encoded provisioning profile; the provisioning profile config in project files will be overwritten by the value.
`IOS_APPSTORECONNECT_USERID`      | Apple ID used to upload the archive to AppStoreConnect.
`IOS_APPSTORECONNECT_PASSWORD`    | Password for the Apple ID.

### Others

Name               | Description
-------------------|------------------------
`SLACK_WEBHOOK`    | For Slack notification.

### Checking configuration of the project

You can use `scripts/find_mobileprovision.sh` to see the configuration. It should be used after successful build of the app. Only the argument to the command is a part of bundle ID of the app.

```
$ ./scripts/find_mobileprovision.sh CameraTest2
Prov. Profile: 11111111-2222-3333-4444-555566667777.mobileprovision
Developer S/N: 0123456789012345678
Bundle ID:     XXXXXXXXXX.com.example.CameraTest2
Team ID:       XXXXXXXXXX
Certificate:   "Apple Distribution: Example Company (XXXXXXXXXX)"
Cert. S/N:     YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
```

### Note on BASE64 encode

To encode files in BASE64, you can use `base64` command.

On Linux,

```
base64 -w0 < target_file
```

On Mac, you don't have `-w0` option. Just remove the option:

```
base64 < target_file
```

## Changes on Flutter default/generated files

- `.github/workflows/main.yml` (added)
    - GitHub Actions workflow definition
- `android/app/build.gradle` (modified)
    - Add actual logic to upload the build result
    - Importing signing/upload configs from auto-generated `android/publish.properties`
    - `android/publish.properties` will be updated by `scripts/generate_pubprops.sh`
- `android/build.gradle` (modified)
    - [Gradle Play Publisher (com.github.triplet.gradle:play-publisher)](https://github.com/Triple-T/gradle-play-publisher) to automatically upload appbundle to Google Play
- `android/gradle/wrapper/gradle-wrapper.properties` (modified)
    - Gradle Play Publisher requires newer gradle (`distributionUrl=https\://services.gradle.org/distributions/gradle-6.3-all.zip`)
- `ios/Runner.xcodeproj/project.pbxproj` (modified)
    - For "Release", use "Manual" signing rather than Xcode automatic signing
    - `CODE_SIGN_STYLE`, `DEVELOPMENT_TEAM`, and, `PROVISIONING_PROFILE_SPECIFIER` will be working as placeholders for the values defined in secrets
    - Will be updated by `scripts/customize.sh` and `scripts/mobileprovision.sh`.
- `lib/buildConfig.dart` (added)
    - Placeholder for build-time configuration variables:
        - `isDebug`, `appCommit`, `appBranch`, `appVersion`, `flutterVersion`, `flutterFullVersionInfo`
        - Will be updated by `scripts/version.sh`
- `scripts/` (added)
    - Shell scripts that automate the build
    - Installing Flutter master (Wow!, but it can be fastest on clone) by `scripts/install_flutter.sh`
