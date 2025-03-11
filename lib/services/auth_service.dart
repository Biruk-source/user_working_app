import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Biometric authentication related fields
  bool _isBiometricAvailable = false;
  final _storage = const FlutterSecureStorage();

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Check if the user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Initialize auth state
  Future<void> initializeAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      await prefs.setBool('isLoggedIn', true);
      // Check biometric availability
      _isBiometricAvailable = await _checkBiometricAvailability();
    } else {
      await prefs.setBool('isLoggedIn', false);
    }
  }

  // Check if biometric authentication is available
  Future<bool> _checkBiometricAvailability() async {
    final localAuth = LocalAuthentication();
    try {
      final isAvailable = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Save credentials for biometric login
  Future<void> saveBiometricCredentials(String email, String password) async {
    if (!_isBiometricAvailable) return;

    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
    await _storage.write(key: 'biometric_enabled', value: 'true');

    // Store in Firebase for cross-device sync
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'biometric_enabled': true,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Authenticate using biometrics
  Future<UserCredential?> authenticateWithBiometrics() async {
    if (!_isBiometricAvailable) return null;

    final localAuth = LocalAuthentication();
    try {
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        final email = await _storage.read(key: 'email');
        final password = await _storage.read(key: 'password');

        if (email != null && password != null) {
          return await signInWithEmailAndPassword(email, password);
        }
      }
    } catch (e) {
      print('Biometric authentication error: $e');
    }
    return null;
  }

  // Check if biometric login is enabled for current user
  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    return enabled == 'true';
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      // Clear any existing sign-in state
      await signOut();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred during sign-up.";
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print(
          'Let\'s go 1: Clearing any existing sessions'); // Step 1: Clear previous sessions
      await _auth.signOut();

      print('Let\'s go 2: Attempting to sign in'); // Step 2: Try signing in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Let\'s go 3: Checking if user exists'); // Step 3: Validate user
      if (credential.user == null) {
        throw FirebaseAuthException(
          code: 'auth/invalid-credential',
          message: 'Sign in failed - no user returned',
        );
      }

      print(
          'Let\'s go 4: Updating login state in SharedPreferences'); // Step 4: Save login status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      print(
          'Let\'s go 5: Sign-in successful! Returning credential'); // Step 5: Return success
      return credential;
    } on FirebaseAuthException catch (e) {
      print(
          'Let\'s go 6: Handling FirebaseAuthException'); // Step 6: Handle authentication errors

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          print('Let\'s go 7: User not found');
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          print('Let\'s go 8: Wrong password');
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          print('Let\'s go 9: Invalid email');
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          print('Let\'s go 10: User disabled');
          break;
        case 'too-many-requests':
          message = 'Too many failed login attempts. Please try again later';
          print('Let\'s go 11: Too many requests');
          break;
        default:
          message = e.message ?? 'Authentication failed';
          print('Let\'s go 12: Unknown Firebase error');
      }

      throw FirebaseAuthException(
        code: e.code,
        message: message,
      );
    } catch (e) {
      print(
          'Let\'s go 13: Handling unexpected error: ${e.toString()}'); // Step 13: Catch general errors

      throw FirebaseAuthException(
        code: 'auth/unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Save user info to secure storage
      if (userCredential.user != null) {
        await _storage.write(
            key: 'user_email', value: userCredential.user!.email);
        await _storage.write(
            key: 'user_name', value: userCredential.user!.displayName);
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('Error signing out from Google: $e');
      }

      try {
        await _auth.signOut();
      } catch (e) {
        print('Error signing out from Firebase: $e');
      }
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }
}
