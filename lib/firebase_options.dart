import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Flutter project.
///
/// This stub class is provided for safe initial compilation. You can easily
/// overwrite this file by running the FlutterFire CLI:
/// `flutterfire configure`
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_5rmgiUZO4Dz4Qb8ob-5dlPy4FXvju4g',
    appId: '1:213207793107:android:4fe7c2d5be1d4904040326',
    messagingSenderId: '213207793107',
    projectId: 'chating-a4ae8',
    storageBucket: 'chating-a4ae8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD477WoZkFp90LxPe6ogMHQNuGJlUQT1dk',
    appId: '1:213207793107:ios:c1b201969cb4d6c7040326',
    messagingSenderId: '213207793107',
    projectId: 'chating-a4ae8',
    storageBucket: 'chating-a4ae8.firebasestorage.app',
    iosBundleId: 'com.premium.chat.chat',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDGdkidRoQE-pM26vawW88_IKbGxOVemGk',
    appId: '1:213207793107:web:974438e998ff7cfa040326',
    messagingSenderId: '213207793107',
    projectId: 'chating-a4ae8',
    authDomain: 'chating-a4ae8.firebaseapp.com',
    storageBucket: 'chating-a4ae8.firebasestorage.app',
  );
}