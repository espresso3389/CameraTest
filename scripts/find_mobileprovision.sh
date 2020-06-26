#!/bin/bash

BUNDLE_ID=$1

cd ~/Library/MobileDevice/Provisioning\ Profiles

# search mobileprovision file corresponding to specified BUNDLE_ID
for mopro in *.mobileprovision
do
  bundle_id=$(security cms -D -i $mopro | grep $BUNDLE_ID | head -1 | sed -E "s/.+<string>(.+)<\/string>/\1/g")
  if [ ! "$bundle_id" = "" ]; then
    break
  fi
done

# get provisioning profile's developer serial number
SERIAL_NUMBER=$(/usr/libexec/PlistBuddy -c "Print DeveloperCertificates:0" /dev/stdin <<< $(security cms -D -i $mopro) | openssl x509 -inform der -text -noout | grep "Serial Number" | awk '{ print $3 }')

bundle_id_parts=(${bundle_id//./ })
team_id=${bundle_id_parts[0]}

# search matching certificate
re="^[0-9]+\) ([0-9A-F]+) \"(.+)\"$"
while read line; do
    if [[ $line =~ $re ]]; then
        cert_id=${BASH_REMATCH[1]}
        cert_name=${BASH_REMATCH[2]}
        break
    fi
done < <(security find-identity -v -p codesigning | grep $team_id | grep Distribution)

echo "Prov. Profile: $mopro"
echo "Developer S/N: $SERIAL_NUMBER"
echo "Bundle ID:     $bundle_id"
echo "Team ID:       $team_id"
echo "Certificate:   \"$cert_name\""
echo "Cert. S/N:     $cert_id"

echo ""

echo "IOS_PROVISIONING_PROFILE_BASE64:"
base64 < $mopro
