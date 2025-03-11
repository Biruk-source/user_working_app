import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web configuration is not available. Please configure Firebase for Web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS configuration is not available. Please configure Firebase for iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS configuration is not available. Please configure Firebase for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows configuration is not available. Please configure Firebase for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux configuration is not available. Please configure Firebase for Linux.',
        );
      default:
        throw UnsupportedError(
          'Unknown platform. Please configure Firebase for your platform.',
        );
    }
  }

    static const FirebaseOptions android = FirebaseOptions(
      apiKey: 'AIzaSyDQOsgFTJlIyRU6kLKUWBsiyeIhVVNVAQ0', // API Key
      appId: '1:973044924282:android:311efffa64f688dc4fa0c3', // App ID
      messagingSenderId: '973044924282', // Sender ID
      projectId: 'gbwork-852ce', // Project ID
      storageBucket: 'gbwork-852ce.firebasestorage.app', // Storage Bucket
    );
}
