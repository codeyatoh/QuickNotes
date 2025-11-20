import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase configuration loaded from .env file
/// 
/// Make sure to:
/// 1. Copy .env.example to .env
/// 2. Fill in your Firebase values from Firebase Console
/// 3. Run: flutter pub get
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.macOS:
        return _macos;
      case TargetPlatform.windows:
        return _windows;
      case TargetPlatform.linux:
        return _linux;
      default:
        return _web;
    }
  }

  static FirebaseOptions get _android {
    // Read from .env file
    final apiKey = dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
    final appId = dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
    final messagingSenderId = dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';

    if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty) {
      throw Exception(
        'Firebase Android configuration missing!\n'
        'Please check your .env file and ensure all FIREBASE_ANDROID_* values are set:\n'
        '- FIREBASE_ANDROID_API_KEY\n'
        '- FIREBASE_ANDROID_APP_ID\n'
        '- FIREBASE_ANDROID_MESSAGING_SENDER_ID\n'
        '- FIREBASE_PROJECT_ID\n'
        '- FIREBASE_STORAGE_BUCKET\n'
        'See FIREBASE_SETUP_GUIDE.md for reference.',
      );
    }

    return FirebaseOptions(
      apiKey: apiKey.trim(), // Remove any whitespace
      appId: appId.trim(),
      messagingSenderId: messagingSenderId.trim(),
      projectId: projectId.trim(),
      storageBucket: storageBucket.trim(),
    );
  }

  static FirebaseOptions get _ios {
    // Use Android values as fallback for iOS if iOS-specific values aren't set
    final apiKey = dotenv.env['FIREBASE_IOS_API_KEY'] ?? 
                   dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
    final appId = dotenv.env['FIREBASE_IOS_APP_ID'] ?? 
                  dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
    final messagingSenderId = dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
      iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '',
    );
  }

  static FirebaseOptions get _macos {
    // Use Android values as fallback for macOS if macOS-specific values aren't set
    final apiKey = dotenv.env['FIREBASE_MACOS_API_KEY'] ?? 
                   dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
    final appId = dotenv.env['FIREBASE_MACOS_APP_ID'] ?? 
                  dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
    final messagingSenderId = dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
      iosBundleId: dotenv.env['FIREBASE_MACOS_BUNDLE_ID'] ?? '',
    );
  }

  static FirebaseOptions get _windows {
    // Use Android values as fallback for Windows if Windows-specific values aren't set
    final apiKey = dotenv.env['FIREBASE_WINDOWS_API_KEY'] ?? 
                   dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
    final appId = dotenv.env['FIREBASE_WINDOWS_APP_ID'] ?? 
                  dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
    final messagingSenderId = dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
    );
  }

  static FirebaseOptions get _linux {
    // Use Android values as fallback for Linux if Linux-specific values aren't set
    final apiKey = dotenv.env['FIREBASE_LINUX_API_KEY'] ?? 
                   dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
    final appId = dotenv.env['FIREBASE_LINUX_APP_ID'] ?? 
                  dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
    final messagingSenderId = dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
    );
  }

  static FirebaseOptions get _web {
    // Use Android values as fallback for web if web-specific values aren't set
    final apiKey = dotenv.env['FIREBASE_WEB_API_KEY'] ?? 
                   dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
    final appId = dotenv.env['FIREBASE_WEB_APP_ID'] ?? 
                  dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
    final messagingSenderId = dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
    
    // Generate authDomain from projectId if not provided
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 
                       (projectId.isNotEmpty ? '$projectId.firebaseapp.com' : '');
    
    // Debug output
    if (kDebugMode) {
      print('🔍 Web Firebase Config:');
      print('  API Key: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 10)}..." : "EMPTY"}');
      print('  App ID: ${appId.isNotEmpty ? appId : "EMPTY"}');
      print('  Project ID: ${projectId.isNotEmpty ? projectId : "EMPTY"}');
      print('  Auth Domain: $authDomain');
    }
    
    if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty) {
      throw Exception(
        'Firebase Web configuration missing!\n'
        'API Key: ${apiKey.isEmpty ? "MISSING" : "OK"}\n'
        'App ID: ${appId.isEmpty ? "MISSING" : "OK"}\n'
        'Project ID: ${projectId.isEmpty ? "MISSING" : "OK"}\n'
        'Please check your .env file and ensure FIREBASE_PROJECT_ID and at least '
        'FIREBASE_ANDROID_API_KEY and FIREBASE_ANDROID_APP_ID are set.\n'
        'Web will use Android values as fallback if FIREBASE_WEB_* values are not provided.',
      );
    }

    return FirebaseOptions(
      apiKey: apiKey.trim(), // Remove any whitespace
      appId: appId.trim(),
      messagingSenderId: messagingSenderId.trim(),
      projectId: projectId.trim(),
      authDomain: authDomain.trim(),
      storageBucket: storageBucket.trim(),
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID']?.trim() ?? '',
    );
  }
}
