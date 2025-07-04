// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAoOPBPKnb6QvRomZp3WBLqvZwHRragdu8',
    appId: '1:47148260136:web:f0eac9802e5e7de55f0e1d',
    messagingSenderId: '47148260136',
    projectId: 'attendance-c02a2',
    authDomain: 'attendance-c02a2.firebaseapp.com',
    storageBucket: 'attendance-c02a2.firebasestorage.app',
    measurementId: 'G-ZY4H39D7BQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbNvdGpNAhLdz0atsP35cG9LP7nbczld8',
    appId: '1:47148260136:android:7cf1755eeed4f12c5f0e1d',
    messagingSenderId: '47148260136',
    projectId: 'attendance-c02a2',
    storageBucket: 'attendance-c02a2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCRzm5U9O8oNLkSgLVLaTq-CqNROJyaIMQ',
    appId: '1:47148260136:ios:57c4482bd6f200ab5f0e1d',
    messagingSenderId: '47148260136',
    projectId: 'attendance-c02a2',
    storageBucket: 'attendance-c02a2.firebasestorage.app',
    iosBundleId: 'com.example.attendanceApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCRzm5U9O8oNLkSgLVLaTq-CqNROJyaIMQ',
    appId: '1:47148260136:ios:57c4482bd6f200ab5f0e1d',
    messagingSenderId: '47148260136',
    projectId: 'attendance-c02a2',
    storageBucket: 'attendance-c02a2.firebasestorage.app',
    iosBundleId: 'com.example.attendanceApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAoOPBPKnb6QvRomZp3WBLqvZwHRragdu8',
    appId: '1:47148260136:web:c8c86becfe182b705f0e1d',
    messagingSenderId: '47148260136',
    projectId: 'attendance-c02a2',
    authDomain: 'attendance-c02a2.firebaseapp.com',
    storageBucket: 'attendance-c02a2.firebasestorage.app',
    measurementId: 'G-LE2XXQWRT4',
  );
}
