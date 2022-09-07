#!/bin/bash
set -ex

if [[ ! -f $pubspec_path ]]
then
	echo "No pubspec file found at path: ${pubspec_path}"
	exit 1
fi

VERSION=`awk '/^version:/ {print $2}' ${pubspec_path}`

IFS='+'
read -a split <<< "${VERSION}"

build_version="${split[0]}"
build_number="${split[1]}"


IFS='.'
read -a version_split <<< "${build_version}"

version_length="${#version_split[@]}"

case $version_auto_increment_mode in
"patch")
  version_split[$((version_length-1))]=$((version_split[$((version_length-1))]+1))
  ;;
"minor")
  if [[ $version_length == 3 ]]
  then
      version_split[1]=$((version_split[1]+1))
      range_start=2
      range_end=$((version_length-1))
      for (( i=$range_start; i<=$range_end; i++ ))
      do
        version_split[$i]=0
      done
  fi
  ;;
"major")
  version_split[0]=$((version_split[0]+1))
  range_start=1
  range_end=$((version_length-1))
  for (( i=$range_start; i<=$range_end; i++ ))
  do
    version_split[$i]=0
  done
  ;;
"none")
  ;;
esac


new_build_number=$build_number


if [[ $increment_build_number == yes ]]
then
  new_build_number=$((build_number+1))
fi

new_build_version=$(IFS=. ; echo "${version_split[*]}")
new_version="${new_build_version}+${new_build_number}"

searchQuery="version: ${VERSION}"
replacedQuery="version: ${new_version}"

sed -i'.backup' "s/$searchQuery/$replacedQuery/g" "${pubspec_path}"

rm "${pubspec_path}.backup"

envman add --key INCREMENTED_VERSION --value "${new_version}"
envman add --key INCREMENTED_VERSION_NAME --value "${new_build_version}"
envman add --key INCREMENTED_BUILD_NUMBER --value "${new_build_number}"

exit 0