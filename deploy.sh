#!/bin/zsh
flutter clean
flutter pub get
dart format lib
dart analyze lib
dart pub publish -f