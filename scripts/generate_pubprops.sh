#!/bin/sh

# Generating publish.properties and serviceaccount.json that is vital to build/upload Android app.

PROPS_FILEPATH=$GITHUB_WORKSPACE/android/publish.properties
KEYSTORE_FILEPATH=$GITHUB_WORKSPACE/android/keystore
ANDROID_SERVICEACCOUNT_JSON_FILEPATH=$GITHUB_WORKSPACE/android/serviceaccount.json

echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > $KEYSTORE_FILEPATH
echo "$ANDROID_SERVICEACCOUNT_JSON_BASE64" | base64 -d > $ANDROID_SERVICEACCOUNT_JSON_FILEPATH

cat > $PROPS_FILEPATH <<EOS
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyPassword=${ANDROID_KEY_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
storeFile=${KEYSTORE_FILEPATH}
uploadKeyJson=${ANDROID_SERVICEACCOUNT_JSON_FILEPATH}
uploadTrack=${ANDROID_UPLOAD_TRACK}
EOS
