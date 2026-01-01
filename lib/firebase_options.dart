import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAP3E8I1Fe8OoIThT9oPqvcEqXvC2321kc',
    appId: '1:1001711203204:web:633e2cf95a0e521bb923d1',
    messagingSenderId: '1001711203204',
    projectId: 'bneeds-taxi-driver-5ecff',
    authDomain: 'bneeds-taxi-driver-5ecff.firebaseapp.com',
    storageBucket: 'bneeds-taxi-driver-5ecff.firebasestorage.app',
    measurementId: 'G-4S98QTVM4Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAP3E8I1Fe8OoIThT9oPqvcEqXvC2321kc',
    appId:
        '1:1001711203204:android:633e2cf95a0e521bb923d1', // Assuming similar structure if not provided
    messagingSenderId: '1001711203204',
    projectId: 'bneeds-taxi-driver-5ecff',
    storageBucket: 'bneeds-taxi-driver-5ecff.firebasestorage.app',
  );
}
