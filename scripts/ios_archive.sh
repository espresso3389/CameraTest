#/bin/sh

distdir=.dist
archdir=.archive
exportOptionsPlist=exportOptions.plist
archiveFileName=apparchive-.xcarchive
mkdir -p ${archdir} ${distdir}

function error_and_die() {
  message "$1"
  exit 1
}

# build archive
xcodebuild \
-workspace Runner.xcworkspace \
-scheme Runner \
-configuration Release archive \
-archivePath ${archiveFileName} \
-allowProvisioningUpdates \
DEVELOPMENT_TEAM=$IOS_APPSTORECONNECT_TEAMID \
|| error_and_die "xcodebuild failed."

# generate exportOptions.plist
cat > ${exportOptionsPlist} <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>${APP_ID}</key>
    <string>${PROVISIONING_PROFILE_ID}</string>
  </dict>
</dict>
</plist>
</dict>
</plist>
EOS

# export archive
xcodebuild \
-exportArchive \
-archivePath ${archiveFileName} \
-exportPath ${distdir} \
-exportOptionsPlist ${exportOptionsPlist} \
-allowProvisioningUpdates \
DEVELOPMENT_TEAM=$IOS_APPSTORECONNECT_TEAMID \
|| error_and_die "xcodebuild -exportArchive failed."

### locating *.ipa file
ipafile=`find ${distdir} -name *.ipa|head -1`
if [ "${ipafile}" = "" ]; then
error_and_die "Build failed."
fi
echo "IPA file: ${ipafile}"

### uploading or verification-only
echo "Verifying/Uploading ${ipafile}..."
xcrun altool --upload-app -f "${ipafile}" -u "${IOS_APPSTORECONNECT_USERID}" -p "${IOS_APPSTORECONNECT_PASSWORD}"
