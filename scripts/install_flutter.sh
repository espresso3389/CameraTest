#!/bin/bash

# known good master version here
#known_good_flutter_commit=8c3b826ebd550008a23b4e2f50b249facff3004b

# This file is to build app with Flutter master
root=$(pwd)
flutter_dir=$root/flutter
flutter_bin_dir=$flutter_dir/bin
flutter=$flutter_bin_dir/flutter

git clone https://github.com/flutter/flutter.git

if [ "$known_good_flutter_commit" = "" ]; then
    $flutter upgrade
else
    git reset --hard $known_good_flutter_commit
    $flutter doctor -v
fi

flutter_full_version=$(cat $flutter_dir/version)
vers=(${flutter_full_version//./ })
flutter_version=${vers[0]}.${vers[1]}

echo "$flutter_full_version"

echo "::add-path::$flutter_bin_dir"
echo "::set-env name=FLUTTER_HOME::$flutter_dir"
echo "::set-env name=FLUTTER_FULL_VERSION::$flutter_full_version"
echo "::set-env name=FLUTTER_VERSION::$flutter_version"
