import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kDebugMode;
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // Handle auth state changes with proper error handling for web platform
    // Wrap in try-catch to handle type casting errors on web
    try {
      _auth.authStateChanges().handleError((error) {
        // Suppress known web platform type errors (LegacyJavaScriptObject)
        final errorString = error.toString();
        final isKnownWebError = errorString.contains('LegacyJavaScriptObject') || 
                               errorString.contains('is not a subtype') ||
                               errorString.contains('TypeError') ||
                               errorString.contains('UserWeb');
        
        if (isKnownWebError) {
          // Known web platform issue - silently handle
          // These errors don't affect functionality, just type casting on web
          if (kDebugMode) {
            debugPrint('⚠ Suppressed web platform type error (non-critical): LegacyJavaScriptObject');
          }
          // Try to get currentUser as fallback
          try {
            final currentUser = _auth.currentUser;
            if (currentUser != null) {
              _handleAuthStateChange(currentUser);
            } else {
              _user = null;
              _isLoading = false;
              notifyListeners();
            }
          } catch (e) {
            // Ignore fallback errors too
            _user = null;
            _isLoading = false;
            notifyListeners();
          }
        } else {
          // Other errors - log but don't crash
          if (kDebugMode) {
            debugPrint('✗ Auth state stream error: $error');
          }
          try {
            _handleAuthStateChange(_auth.currentUser);
          } catch (e) {
            _user = null;
            _isLoading = false;
            notifyListeners();
          }
        }
      }).listen(
        (firebaseUser) {
          try {
            _handleAuthStateChange(firebaseUser);
          } catch (e) {
            // Handle type casting errors gracefully (common on web with LegacyJavaScriptObject)
            final errorString = e.toString();
            final isTypeError = errorString.contains('LegacyJavaScriptObject') || 
                               errorString.contains('is not a subtype') ||
                               errorString.contains('TypeError');
            
            if (isTypeError) {
              // Known web platform issue - silently handle
              // Try to get currentUser as fallback
              try {
                final currentUser = _auth.currentUser;
                if (currentUser != null) {
                  _handleAuthStateChange(currentUser);
                } else {
                  _user = null;
                  _isLoading = false;
                  notifyListeners();
                }
              } catch (fallbackError) {
                // Ignore fallback errors
                _user = null;
                _isLoading = false;
                notifyListeners();
              }
            } else {
              // Other errors - log but don't crash
              if (kDebugMode) {
                debugPrint('✗ Auth state change handler error: $e');
              }
              try {
                _handleAuthStateChange(_auth.currentUser);
              } catch (fallbackError) {
                _user = null;
                _isLoading = false;
                notifyListeners();
              }
            }
          }
        },
        cancelOnError: false, // Don't cancel stream on error
      );
    } catch (e) {
      // If stream setup fails, use currentUser
      if (kDebugMode) {
        debugPrint('✗ Auth state stream setup error: $e');
      }
      try {
        _handleAuthStateChange(_auth.currentUser);
      } catch (fallbackError) {
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  Future<bool> register(String name, String email, String password) async {
    _lastError = null;
    try {
      if (kDebugMode) {
        debugPrint('📝 Starting registration for: $email');
      }
      
      // Step 1: Create user in Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (kDebugMode) {
        debugPrint('✓ User created in Firebase Authentication: ${credential.user?.uid}');
      }

      // Step 2: Update display name in Authentication
      try {
        await credential.user?.updateDisplayName(name.trim());
        if (kDebugMode) {
          debugPrint('✓ Display name updated in Authentication');
        }
      } catch (e) {
        // Ignore display name update errors (non-critical)
        if (kDebugMode) {
          debugPrint('⚠ Display name update error (non-critical): $e');
        }
      }

      // Step 3: Create user document in Firestore
      final now = FieldValue.serverTimestamp();
      final uid = credential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'id': uid,
        'fullName': name.trim(),
        'email': email.trim(),
        'createdAt': now,
        'updatedAt': now,
        'lastLoginAt': now,
        'onboardingCompleted': false,
        'preferences': {
          'theme': 'light',
          'defaultNoteType': 'note',
          'notifications': {'enabled': true},
        },
        'stats': {
          'noteCount': 0,
          'archivedCount': 0,
        },
      });

      if (kDebugMode) {
        debugPrint('✓ User document created in Firestore: users/$uid');
        debugPrint('✅ Registration successful!');
      }

      // Note: User is automatically logged in after registration
      // They will be navigated to onboarding screen
      // No need to sign out - let them complete onboarding first

      return true;
    } on fb.FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Registration error (Auth): ${e.code} - ${e.message}');
      }
      
      // Set specific error messages
      switch (e.code) {
        case 'weak-password':
          _lastError = 'Password is too weak. Please use at least 6 characters.';
          if (kDebugMode) {
            debugPrint('  → Password is too weak');
          }
          break;
        case 'email-already-in-use':
          _lastError = 'This email is already registered. Please use a different email or try logging in.';
          if (kDebugMode) {
            debugPrint('  → Email is already registered');
          }
          break;
        case 'invalid-email':
          _lastError = 'Invalid email format. Please enter a valid email address.';
          if (kDebugMode) {
            debugPrint('  → Email format is invalid');
          }
          break;
        case 'operation-not-allowed':
          _lastError = 'Email/Password authentication is not enabled. Please contact support.';
          if (kDebugMode) {
            debugPrint('  → Operation not allowed');
          }
          break;
        default:
          _lastError = 'Registration failed: ${e.message ?? e.code}';
          if (kDebugMode) {
            debugPrint('  → ${e.message}');
          }
      }
      
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Registration error: $e');
      }
      _lastError = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (kDebugMode) {
        debugPrint('✓ Login successful');
      }
      return true;
    } on fb.FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Login error: ${e.code} - ${e.message}');
      }
      
      // Set specific error messages
      switch (e.code) {
        case 'user-not-found':
          _lastError = 'No account found with this email. Please register first.';
          break;
        case 'wrong-password':
          _lastError = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          _lastError = 'Invalid email format. Please enter a valid email address.';
          break;
        case 'user-disabled':
          _lastError = 'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          _lastError = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          _lastError = 'Network error. Please check your internet connection.';
          break;
        default:
          _lastError = 'Login failed: ${e.message ?? e.code}';
      }
      
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Login error: $e');
      }
      _lastError = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(
    String name,
    String email,
    String? currentPassword,
    String? newPassword,
  ) async {
    final fb.User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _lastError = 'No user is currently logged in.';
      notifyListeners();
      return false;
    }

    _lastError = null;

    try {
      if (kDebugMode) {
        debugPrint('📝 Starting user profile update...');
      }

        // Step 1: Update email in Firebase Authentication (if changed)
        if (email.trim().isNotEmpty && email.trim() != currentUser.email) {
          if (kDebugMode) {
            debugPrint('  → Updating email in Authentication...');
          }
          await currentUser.updateEmail(email.trim());
          if (kDebugMode) {
            debugPrint('✓ Email updated in Authentication');
          }
        }

        // Step 2: Update password (if provided)
        if (newPassword != null && newPassword.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('  → Updating password in Authentication...');
          }
        if (currentPassword == null || currentPassword.isEmpty) {
          _lastError = 'Current password is required to change password.';
          notifyListeners();
          return false;
        }
        
        final credential = fb.EmailAuthProvider.credential(
          email: currentUser.email!,
          password: currentPassword,
        );
        await currentUser.reauthenticateWithCredential(credential);
          await currentUser.updatePassword(newPassword);
          if (kDebugMode) {
            debugPrint('✓ Password updated in Authentication');
          }
        }

        // Step 3: Update display name in Firebase Authentication
        if (name.trim() != currentUser.displayName) {
          if (kDebugMode) {
            debugPrint('  → Updating display name in Authentication...');
          }
          await currentUser.updateDisplayName(name.trim());
          if (kDebugMode) {
            debugPrint('✓ Display name updated in Authentication');
          }
        }

        // Step 4: Update user document in Firestore
        if (kDebugMode) {
          debugPrint('  → Updating user document in Firestore...');
        }
        await _firestore.collection('users').doc(currentUser.uid).update({
          'fullName': name.trim(),
          'email': email.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) {
          debugPrint('✓ User document updated in Firestore');
        }

        // Step 5: Update local user state
        _user = _user?.copyWith(name: name.trim(), email: email.trim());
        notifyListeners();
        
        if (kDebugMode) {
          debugPrint('✅ User profile updated successfully!');
        }
      return true;
      } on fb.FirebaseAuthException catch (e) {
        if (kDebugMode) {
          debugPrint('✗ Update user error (Auth): ${e.code} - ${e.message}');
        }
      
      // Set specific error messages
      switch (e.code) {
        case 'requires-recent-login':
          _lastError = 'Please log out and log back in before changing your email or password.';
          break;
        case 'email-already-in-use':
          _lastError = 'This email is already in use by another account.';
          break;
        case 'invalid-email':
          _lastError = 'Invalid email format. Please enter a valid email address.';
          break;
        case 'weak-password':
          _lastError = 'Password is too weak. Please use at least 6 characters.';
          break;
        case 'wrong-password':
          _lastError = 'Current password is incorrect. Please try again.';
          break;
        case 'user-mismatch':
          _lastError = 'The provided credentials do not match the current user.';
          break;
        case 'user-not-found':
          _lastError = 'User account not found. Please log in again.';
          break;
        default:
          _lastError = 'Failed to update account: ${e.message ?? e.code}';
      }
      
        notifyListeners();
        return false;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('✗ Update user error: $e');
        }
      _lastError = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Password reset code storage
  final Map<String, Map<String, dynamic>> _passwordResetCodes = {};

  /// Sends a 6-digit password reset code to the user's email
  Future<bool> sendPasswordResetCode(String email) async {
    _lastError = null;
    try {
      // Generate 6-digit code
      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

      // Store code with expiration (15 minutes)
      _passwordResetCodes[email.trim()] = {
        'code': code,
        'expiresAt': DateTime.now().add(const Duration(minutes: 15)),
        'attempts': 0,
      };

      // Store in Firestore
      await _firestore.collection('password_reset_codes').doc(email.trim()).set({
        'code': code,
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
        'used': false,
      });

      // Send email via EmailJS
      try {
        await http.post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'service_id': 'service_trsntbw',
            'template_id': 'template_pkoekec',
            'user_id': '4yKB68hYcpmktraku',
            'template_params': {
              'to_name': email.trim(),
              'to_email': email.trim(),
              'code': code,
            },
          }),
        );
      } catch (emailError) {
        // Email sending failed, but code is still valid
      }

      return true;
    } on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          _lastError = 'Invalid email format.';
          break;
        default:
          _lastError = 'Failed to send reset code: ${e.message ?? e.code}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Verifies the password reset code
  Future<bool> verifyPasswordResetCode(String email, String code) async {
    _lastError = null;
    try {

      // Check stored code in memory
      final storedData = _passwordResetCodes[email.trim()];
      if (storedData != null) {
        if (DateTime.now().isAfter(storedData['expiresAt'] as DateTime)) {
          _passwordResetCodes.remove(email.trim());
          _lastError = 'Code expired. Please request a new code.';
          notifyListeners();
          return false;
        }

        if (storedData['attempts'] >= 5) {
          _passwordResetCodes.remove(email.trim());
          _lastError = 'Too many attempts. Please request a new code.';
          notifyListeners();
          return false;
        }

        if (storedData['code'] != code) {
          storedData['attempts'] = (storedData['attempts'] as int) + 1;
          _lastError = 'Invalid code. Please try again.';
          notifyListeners();
          return false;
        }

        return true;
      }

      // Fallback to Firestore
      final doc = await _firestore.collection('password_reset_codes').doc(email.trim()).get();
      if (!doc.exists) {
        _lastError = 'No reset code found. Please request a new code.';
        notifyListeners();
        return false;
      }

      final data = doc.data()!;
      if (data['used'] == true ||
          DateTime.now().isAfter((data['expiresAt'] as Timestamp).toDate()) ||
          data['code'] != code) {
        _lastError = 'Invalid or expired code.';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _lastError = 'An unexpected error occurred.';
      notifyListeners();
      return false;
    }
  }

  /// Sends Firebase password reset email after code verification
  Future<bool> resetPassword(String email, String code) async {
    _lastError = null;
    try {
      if (!await verifyPasswordResetCode(email, code)) {
        return false;
      }

      // Send Firebase password reset email
      await _auth.sendPasswordResetEmail(email: email.trim());

      // Mark code as used
      _passwordResetCodes.remove(email.trim());
      await _firestore.collection('password_reset_codes').doc(email.trim()).update({
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on fb.FirebaseAuthException catch (e) {

      _lastError = e.code == 'user-not-found'
          ? 'No account found with this email.'
          : 'Failed to send reset email: ${e.message ?? e.code}';

      notifyListeners();
      return false;
    } catch (e) {
      _lastError = 'An unexpected error occurred.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Optimistic update - clear user state immediately
    _user = null;
    _isLoading = false;
    notifyListeners();
    
    // Sign out in background (non-blocking)
    try {
      await _auth.signOut();
    } catch (e) {
      // Log error but don't block - user state is already cleared
      if (kDebugMode) {
        debugPrint('⚠ Logout error (non-critical): $e');
      }
    }
  }

  Future<void> _handleAuthStateChange(dynamic firebaseUser) async {
    // Handle null case
    if (firebaseUser == null) {
      _user = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Type safety check for web platform compatibility
    // On web, firebaseUser might be LegacyJavaScriptObject which can't be cast directly
    fb.User? user;
    try {
      // Try to cast to fb.User, if it fails, use currentUser as fallback
      if (firebaseUser is fb.User) {
        user = firebaseUser;
      } else {
        // For web platform type issues (LegacyJavaScriptObject), use currentUser
        if (kDebugMode) {
          debugPrint('⚠ Auth state type mismatch, using currentUser fallback');
        }
        user = _auth.currentUser;
        if (user == null) {
          _user = null;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      // Catch any type casting errors (e.g., LegacyJavaScriptObject on web)
      if (kDebugMode) {
        debugPrint('✗ Auth state type error: $e');
      }
      // Always fallback to currentUser for web platform compatibility
      try {
        user = _auth.currentUser;
      } catch (currentUserError) {
        if (kDebugMode) {
          debugPrint('✗ Could not get currentUser: $currentUserError');
        }
        _user = null;
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      if (user == null) {
        _user = null;
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    try {
      final uid = user.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final createdAt = data['createdAt'];
        _user = User(
          id: uid,
          name: (data['fullName'] as String?)?.trim() ?? user.displayName ?? '',
          email: (data['email'] as String?)?.trim() ?? user.email ?? '',
          createdAt: createdAt is Timestamp
              ? createdAt.toDate()
              : user.metadata.creationTime ?? DateTime.now(),
        );

        await _firestore.collection('users').doc(uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } else {
        final creationTime = user.metadata.creationTime ?? DateTime.now();
        _user = User(
          id: uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          createdAt: creationTime,
        );

        await _firestore.collection('users').doc(uid).set({
          'id': uid,
          'fullName': user.displayName ?? '',
          'email': user.email ?? '',
          'createdAt': creationTime,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'onboardingCompleted': false,
          'preferences': {
            'theme': 'light',
            'defaultNoteType': 'note',
            'notifications': {'enabled': true},
          },
          'stats': {
            'noteCount': 0,
            'archivedCount': 0,
          },
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Auth state handler error: $e');
      }
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }
}
