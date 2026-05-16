import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';


final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final isGuestProvider = StateProvider<bool>((ref) => true);
final hasSeenOnboardingProvider = StateProvider<bool>((ref) => false);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Standard GoogleSignIn instance - MINIMAL for testing
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '933555779274-babvkfn1rvfl7rufl386cgqq50u12fvl.apps.googleusercontent.com',
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  // Cache the access token directly from GoogleSignInAuthentication
  String? _cachedAccessToken;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      logger.i('Starting Google Sign-In process...');
      
      // Just sign out to be sure
      await _googleSignIn.signOut().catchError((e) {
        logger.w('Sign out error (ignored): $e');
        return null;
      });
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        logger.w('Google Sign-In was canceled by the user.');
        return null;
      }

      logger.i('Google Sign-In successful for: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      
      logger.i('Obtained authentication tokens.');

      // Save access token directly — userCredential.credential is null on Android (fix C2)
      _cachedAccessToken = googleAuth.accessToken;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential;
    } catch (e, stack) {
      logger.e('Error signing in with Google', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Refresh the access token silently for Drive API operations (fix M2)
  /// Call this before every Drive operation to ensure a valid, non-expired token.
  Future<String?> getFreshAccessToken() async {
    try {
      // Try silent sign-in first (no UI)
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      // User needs to explicitly sign in again
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      _cachedAccessToken = googleAuth.accessToken;
      return _cachedAccessToken;
    } catch (e, stack) {
      logger.e('Error refreshing access token', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Use the same instance (fix M1)
    await _auth.signOut();
    _cachedAccessToken = null;
  }

  // Get the cached access token for Drive API
  String? get currentAccessToken => _cachedAccessToken;
}
