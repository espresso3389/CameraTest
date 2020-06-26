#!/bin/sh

#
# Install our provisioning certificates on the runner machine
#
# Reference: https://apple.stackexchange.com/a/285320

MY_KEYCHAIN="temp.keychain"
MY_KEYCHAIN_PASSWORD="secret"
CODESIGN=/usr/bin/codesign

security create-keychain -p "$MY_KEYCHAIN_PASSWORD" "$MY_KEYCHAIN" # Create temp keychain
security list-keychains -d user -s "$MY_KEYCHAIN" $(security list-keychains -d user | sed s/\"//g) # Append temp keychain to the user domain
security set-keychain-settings "$MY_KEYCHAIN" # Remove relock timeout
security unlock-keychain -p "$MY_KEYCHAIN_PASSWORD" "$MY_KEYCHAIN" # Unlock keychain

# Add certificate to keychain
DIST_P12=$GITHUB_WORKSPACE/apple_dist.p12
echo "$P12_BASE64" | base64 -d > $DIST_P12
security import $DIST_P12 -k "$MY_KEYCHAIN" -P "$P12_PASSWORD" -T "$CODESIGN"

# Programmatically derive the identity
CERT_IDENTITY=$(security find-identity -v -p codesigning "$MY_KEYCHAIN" | head -1 | grep '"' | sed -e 's/[^"]*"//' -e 's/".*//')
# Handy to have UUID (just in case)
# CERT_UUID=$(security find-identity -v -p codesigning "$MY_KEYCHAIN" | head -1 | grep '"' | awk '{print $2}')

# Dump certificate details
CERT_TMP=cert.tmp
security find-certificate -c "$CERT_IDENTITY" -p > $CERT_TMP
CERT_TEXT=$(openssl x509 -text -noout -in $CERT_TMP)
echo $CERT_TEXT

# Enable codesigning from a non user interactive shell
security set-key-partition-list -S apple-tool:,apple: -s -k $MY_KEYCHAIN_PASSWORD -D "$CERT_IDENTITY" -t private $MY_KEYCHAIN 

# For deinit keychain
echo "::set-env name=REMOVE_TMP_KEYCHAIN::security delete-keychain $MY_KEYCHAIN"

# Certificate serial number
SERIAL_NUMBER=$(echo "$CERT_TEXT" | grep "Serial Number" | awk '{ print $3 }')
echo "::set-env name=CERT_SERIAL_NUMBER::$SERIAL_NUMBER"

# Checking validity of the certificate anyway
security verify-cert -c $CERT_TMP
