# Flutter Chat App

A polished, real-time cross-platform chat application built with Flutter and Firebase. This project builds upon the original baseline starter to deliver a secure, robust, and full-featured messaging experience.

## Setup

Tested on Flutter stable `3.41.x` (Dart `3.11.x`). Run `flutter --version` to check your channel.

```sh
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure   # against YOUR Firebase project — regenerates lib/firebase_options.dart
flutter run
