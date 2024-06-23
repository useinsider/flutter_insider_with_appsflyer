#!/usr/bin/env bash

NEW_FL_VERSION_NAME=$1

pubspec_file_path="pubspec.yaml"
podspec_file_path="ios/flutter_insider.podspec"
gradle_file_path="android/build.gradle"

CURRENT_FL_SDK_VERSION=$(sed -n 3p $pubspec_file_path | awk '{print $2}')

CURRENT_iOS_VERSION=$(sed -n 15p $podspec_file_path | awk '{print $3}' | sed 's/^.//;s/.$//')
CURRENT_iOS_HYBRID_VERSION=$(sed -n 16p $podspec_file_path | awk '{print $3}' | sed 's/^.//;s/.$//')

CURRENT_ANDROID_VERSION=$(sed -n 43p $gradle_file_path | awk '{print $2}' | awk -F : '{print $3}' | cut -d "'" -f 1)
CURRENT_ANDROID_HYBRID_VERSION=$(sed -n 44p $gradle_file_path | awk '{print $2}' | awk -F : '{print $3}' | cut -d "'" -f 1)

LATEST_iOS_VERSION=$(aws s3 ls s3://mobilesdk.useinsider.com/iOS/ --recursive | sort | tail -n 1 | awk '{print $4}' | awk -F / '{print $2}')
LATEST_iOS_HYBRID_VERSION=$(aws s3 ls s3://mobilesdk.useinsider.com/iOSHybrid/ --recursive | sort | tail -n 1 | awk '{print $4}' | awk -F / '{print $2}')

LATEST_ANDROID_VERSION=$(aws s3 ls s3://mobilesdk.useinsider.com/android/com/useinsider/insider/ --recursive | sort | tail -n 1 | awk '{print $4}' | awk -F / '{print $5}' | cut -d "-" -f 1)
LATEST_ANDROID_HYBRID_VERSION=$(aws s3 ls s3://mobilesdk.useinsider.com/android/com/useinsider/insiderhybrid/ --recursive | sort | tail -n 1 | awk '{print $4}' | awk -F / '{print $5}')

# Set new version in pubspec.yaml
sed -i "s/$CURRENT_FL_SDK_VERSION/$NEW_FL_VERSION_NAME/" $pubspec_file_path

# Set new version in podspec
sed -i "s/$CURRENT_iOS_VERSION/$LATEST_iOS_VERSION/;s/$CURRENT_iOS_HYBRID_VERSION/$LATEST_iOS_HYBRID_VERSION/;s/$CURRENT_FL_SDK_VERSION/$NEW_FL_VERSION_NAME/" $podspec_file_path

# Set new version in build.gradle
sed -i "s/$CURRENT_ANDROID_VERSION/$LATEST_ANDROID_VERSION/;s/$CURRENT_ANDROID_HYBRID_VERSION/$LATEST_ANDROID_HYBRID_VERSION/" $gradle_file_path