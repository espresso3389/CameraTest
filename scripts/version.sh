#/bin/bash

#
# detect latest updated branch
#
data=(`git for-each-ref --format='%(refname) %(objectname)' --sort='-committerdate'`)
refname=${data[0]}
commit=${data[1]}
if [[ "$refname" == "refs/heads/"* ]]; then
  branch=${refname:11}
elif [[ "$refname" == "refs/remotes/origin/"* ]]; then
  branch=${refname:20}
else
  echo "Could not resolve branch name from refname: $refname"
  exit 1
fi

build=0

# revision using GITHUB_RUN_NUMBER
rev=$(($GITHUB_RUN_NUMBER+0))
commit=$(git log --oneline -1 | awk '{print $1}')
ver=1.${rev}.${build}
echo "Version: ${ver} (Rev=${rev}, Build=${build}, Commit=${commit}, Branch=${branch})"

flutter_full_version=$(cat $FLUTTER_HOME/version)
vers=(${flutter_full_version//./ })
flutter_version=${vers[0]}.${vers[1]}

flutter_desc=$(flutter --version)

# Update GitHub Actions environment variables
echo "::set-env name=app_ver::$ver"
echo "::set-env name=app_rev::$rev"
echo "::set-env name=app_build_name::$ver-$commit"
echo "::set-env name=app_branch::$branch"

# Update lib/buildConfig.dart
buildConfig='lib/buildConfig.dart'
cat > $buildConfig <<EOS
final isDebug = false;
final appCommit = '${commit}';
final appBranch = '${branch}';
final appVersion = '${ver}';
final flutterVersion = '${flutter_full_version}';
final flutterFullVersionInfo = '''$flutter_desc''';
EOS
