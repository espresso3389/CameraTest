#/bin/bash

if [[ "$app_branch" == "" ]]; then
  echo "Could not get app_branch."
  exit 1
fi

echo "::set-env name=android_app_id::$ANDROID_APP_ID"
echo "::set-env name=ios_bundle_id::$IOS_BUNDLE_ID"
echo "::set-env name=ios_team_id::$IOS_TEAM_ID"

# android/app/build.gradle
sed -i.bak \
  -E "s/(applicationId )\"[_A-Za-z0-9\.]+\"/\1\"${ANDROID_APP_ID}\"/g" \
  android/app/build.gradle

###
updated_appid=$(cat android/app/build.gradle | grep applicationId)
echo "Updated appID: $updated_appid"

# ios/Runner.xcodeproj/project.pbxproj
sed -i.bak \
  -E "s/(PRODUCT_BUNDLE_IDENTIFIER = )\"[_A-Za-z0-9\.\-]+\"/\1\"${BUNDLE_ID}\"/g; s/(DEVELOPMENT_TEAM = )[\"A-Z0-9]+/\1${TEAM_ID}/g; s/(PROVISIONING_PROFILE_SPECIFIER = )[\"\-_A-Za-z0-9 ]+/\1\"${PROV_PROFILE_SPECIFIER}\"/g" \
  ios/Runner.xcodeproj/project.pbxproj
