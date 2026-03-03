import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';

// User Role Enum
enum UserRole { admin, manager, staff, unknown }

// Custom User Model
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.unknown,
  });

  factory AppUser.fromFirebaseUser(
    firebase_auth.User user, {
    UserRole role = UserRole.unknown,
  }) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      role: role,
    );
  }
}

// State enum for Authentication
enum AuthState { initial, loading, authenticated, unauthenticated, error }

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    firebaseAuth: firebase_auth.FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(
      serverClientId:
          '63402102575-vku6c2v51doepvh8kf7lqjd4283ekgdv.apps.googleusercontent.com',
    ),
    secureStorage: const FlutterSecureStorage(),
    localAuth: LocalAuthentication(),
  );
});

// The core Auth Service class
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  AuthService({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FlutterSecureStorage secureStorage,
    required LocalAuthentication localAuth,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _secureStorage = secureStorage,
       _localAuth = localAuth;

  // Stream of Firebase Auth State Changes
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // Current User
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  // 1. Google Sign-In
  Future<AppUser?> signInWithGoogle() async {
    try {
      // Sign out first to force account picker
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final firebase_auth.OAuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        return AppUser.fromFirebaseUser(userCredential.user!);
      }
      return null;
    } catch (e) {
      throw Exception('Google Sign-In Failed: $e');
    }
  }

  // 2. Email & Password Sign Up
  Future<AppUser?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        return AppUser.fromFirebaseUser(userCredential.user!);
      }
      return null;
    } catch (e) {
      throw Exception('Sign Up Failed: $e');
    }
  }

  // 3. Email & Password Login
  Future<AppUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        return AppUser.fromFirebaseUser(userCredential.user!);
      }
      return null;
    } catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  // 4. Biometric Authentication
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason:
            'Please authenticate to log in to Dhaara Business Manager',
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    await _secureStorage.delete(key: 'biometric_enabled');
  }

  // Session token helpers (Secure Storage)
  Future<void> enableBiometricLogin(bool isEnabled) async {
    await _secureStorage.write(
      key: 'biometric_enabled',
      value: isEnabled.toString(),
    );
  }

  Future<bool> isBiometricLoginEnabled() async {
    final value = await _secureStorage.read(key: 'biometric_enabled');
    return value == 'true';
  }
}
