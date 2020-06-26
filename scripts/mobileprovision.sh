#/bin/sh

PROVPROF_TMP=$GITHUB_WORKSPACE/tmp.mobileprovision

echo "$IOS_PROVISIONING_PROFILE_BASE64" | base64 -d > $PROVPROF_TMP
UUID=`grep UUID -A1 -a $PROVPROF_TMP | grep -io "[-A-Z0-9]\{36\}"`
echo "Provisioning profile UUID: $UUID"

SERIAL_NUMBER=$(/usr/libexec/PlistBuddy -c "Print DeveloperCertificates:0" /dev/stdin <<< $(security cms -D -i $PROVPROF_TMP) | openssl x509 -inform der -text -noout | grep "Serial Number" | awk '{ print $3 }')

# Checking provisioning profile's developer
if [ "$CERT_SERIAL_NUMBER" = "$SERIAL_NUMBER" ]; then
    echo "Provisioning profile's developer match to certificate's one: $SERIAL_NUMBER"
else
    echo "Provisioning profile's developer not match to certificate's one: $SERIAL_NUMBER <-> $CERT_SERIAL_NUMBER"
    exit 1
fi

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
mv $PROVPROF_TMP ~/Library/MobileDevice/Provisioning\ Profiles/$UUID.mobileprovision

# ios/Runner.xcodeproj/project.pbxproj
sed -i.bak \
  -E "s/(PROVISIONING_PROFILE_SPECIFIER = )\".*\"/\1\"${UUID}\"/g" \
  ios/Runner.xcodeproj/project.pbxproj
