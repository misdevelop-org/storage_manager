#!/bin/zsh
# Manual release: bump pubspec.yaml + CHANGELOG.md first, then run this script.
set -e
flutter pub get
dart format -l 120 lib test
flutter analyze
flutter test
flutter pub publish --dry-run
flutter pub publish
