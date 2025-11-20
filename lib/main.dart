import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/notes/home_screen.dart';
import 'screens/notes/create_note_screen.dart';
import 'screens/notes/edit_note_screen.dart';
import 'screens/notes/note_details_screen.dart';
import 'screens/notes/archive_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/account_settings_screen.dart';
import 'utils/async_util.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: DevTools warnings for Flutter web are normal and can be safely ignored:
  // - "Failed to set DevTools server address: ext.flutter.activeDevToolsServerAddress: (-32601) Unknown method"
  // - "ext.flutter.connectedVmServiceUri: (-32601) Unknown method"
  // - "Failed to set vm service URI: ext.flutter.connectedVmServiceUri: (-32601) Unknown method"
  // - "Unexpected DWDS error for callServiceExtension: WipError -32000 Promise was collected"
  // - "Deep links to DevTools will not show in Flutter errors"
  // These warnings occur because Flutter web doesn't support the same DevTools extensions
  // as mobile/desktop platforms. They are framework-level warnings that cannot be suppressed
  // programmatically and do not affect app functionality. This is expected behavior for Flutter web.
  
  // Load .env file - must load before Firebase initialization
  try {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) {
      debugPrint('✓ .env file loaded successfully');
      
      // Debug: Print loaded values (without exposing full API key)
      final apiKey = dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
      if (apiKey.isNotEmpty) {
        debugPrint('✓ API Key loaded: ${apiKey.substring(0, 10)}...');
      } else {
        debugPrint('⚠ API Key is empty!');
      }
      if (projectId.isNotEmpty) {
        debugPrint('✓ Project ID: $projectId');
      } else {
        debugPrint('⚠ Project ID is empty!');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠ Warning: Could not load .env file: $e');
      debugPrint('⚠ Make sure .env file exists in the root directory.');
      debugPrint('⚠ Firebase initialization may fail without proper configuration.');
    }
  }
  
  // Initialize Firebase with error handling and duplicate check
  try {
    // Check if Firebase is already initialized (for hot restart)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        debugPrint('✓ Firebase initialized successfully');
      }
    } else {
      if (kDebugMode) {
        debugPrint('✓ Firebase already initialized (hot restart detected)');
      }
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      if (kDebugMode) {
        debugPrint('⚠ Firebase app already exists, using existing instance');
      }
    } else {
      if (kDebugMode) {
        debugPrint('✗ Firebase initialization failed: ${e.code} - ${e.message}');
        debugPrint('✗ Please check your .env file configuration.');
      }
      rethrow;
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('✗ Firebase initialization failed: $e');
      debugPrint('✗ Please check your .env file configuration.');
    }
    rethrow; // Re-throw to show error in UI
  }
  
  runApp(const QuickNotesApp());
}

class QuickNotesApp extends StatelessWidget {
  const QuickNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserSettingsProvider>(
          create: (_) => UserSettingsProvider(),
          update: (_, authProvider, userSettings) {
            userSettings ??= UserSettingsProvider();
            final userId = authProvider.user?.id;
            if (userId != null && userSettings.userId != userId) {
              unawaited(userSettings.startListening(userId));
            } else if (userId == null) {
              unawaited(userSettings.stopListening());
            }
            return userSettings;
          },
        ),
        ChangeNotifierProxyProvider<UserSettingsProvider, NotesProvider>(
          create: (_) => NotesProvider(),
          update: (context, userSettings, notesProvider) {
            notesProvider ??= NotesProvider();
            notesProvider.setUserSettingsProvider(userSettings);
            // Get userId from AuthProvider via context
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final userId = authProvider.user?.id;
            if (userId != null) {
              unawaited(notesProvider.startListening(userId));
            } else {
              unawaited(notesProvider.clear());
            }
            return notesProvider;
          },
        ),
        ChangeNotifierProxyProvider<UserSettingsProvider, ThemeProvider>(
          create: (_) => ThemeProvider(),
          update: (_, userSettings, themeProvider) {
            themeProvider ??= ThemeProvider();
            unawaited(themeProvider.init(userSettingsProvider: userSettings));
            themeProvider.updateFromUserSettings(userSettings);
            return themeProvider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'QuickNotes',
            debugShowCheckedModeBanner: false,
            // Safe builder to prevent window.dart errors
            builder: (context, child) {
              // Ensure we have a valid context and child
              if (child == null) {
                return const SizedBox.shrink();
              }
              
              // Safely get MediaQuery data - use try-catch to prevent window.dart errors
              try {
                final mediaQuery = MediaQuery.maybeOf(context);
                if (mediaQuery != null) {
                  return MediaQuery(
                    data: mediaQuery.copyWith(textScaler: TextScaler.linear(1.0)),
                    child: child,
                  );
                }
              } catch (e) {
                // If MediaQuery access fails, just return child without modification
                if (kDebugMode) {
                  debugPrint('MediaQuery builder error (safe to ignore): $e');
                }
              }
              
              // Fallback if MediaQuery is not available
              return child;
            },
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                },
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                },
              ),
            ),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const HomeScreen(),
              '/create': (context) => const CreateNoteScreen(),
              '/archive': (context) => const ArchiveScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/account-settings': (context) => const AccountSettingsScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle routes with parameters
              final routeName = settings.name;
              if (routeName == null) return null;

              // Handle /note/:id routes
              if (routeName.startsWith('/note/')) {
                final noteId = routeName.split('/').last;
                return PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      NoteDetailsScreen(noteId: noteId),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    // Use simple fade transition without Hero widgets
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                  reverseTransitionDuration: const Duration(milliseconds: 200),
                  settings: settings,
                );
              }

              // Handle /edit/:id routes
              if (routeName.startsWith('/edit/')) {
                final noteId = routeName.split('/').last;
                return PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      EditNoteScreen(noteId: noteId),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    // Use simple fade transition without Hero widgets
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                  reverseTransitionDuration: const Duration(milliseconds: 200),
                  settings: settings,
                );
              }

              return null;
            },
          );
        },
      ),
    );
  }
}
