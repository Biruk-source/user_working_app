import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:email_validator/email_validator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:custom_progress_button/custom_progress_button.dart'
    show ButtonState;
import 'background.dart';
import 'widget_custom.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final storage = const FlutterSecureStorage();

  ButtonState stateOnlyCustomIndicatorText = ButtonState.idle;
  ButtonState googleSignInButtonState = ButtonState.idle;

  double touchX = 0;
  double touchY = 0;
  bool isTouched = true;

  bool _isAuthenticated = false;
  bool _biometricSupported = false;
  bool _isRegistered = false;
  String _authenticationStatus = 'Not Authenticated';
  bool _isProcessing = false;

  String username = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _checkBiometricSupport();
    _checkCredentials();
    _checkAuthenticationStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricSupport() async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    bool isDeviceSupported = await _localAuth.isDeviceSupported();
    setState(() {
      _biometricSupported = canCheckBiometrics && isDeviceSupported;
    });
  }

  Future<void> _checkCredentials() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _isRegistered = true;
        });
      } else {
        final username = await storage.read(key: 'username');
        final password = await storage.read(key: 'password');
        if (username != null && password != null) {
          setState(() {
            _isRegistered = true;
          });
        }
      }
    } catch (e) {
      print("Error checking credentials: $e");
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    });
  }

  Future<void> _authenticate() async {
    setState(() {
      _isProcessing = true;
    });

    bool authenticated = false;
    try {
      if (!_biometricSupported) {
        setState(() {
          _authenticationStatus = 'Biometric authentication not supported';
        });
        return;
      }

      authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        final user = _auth.currentUser;
        if (user != null) {
          _authenticationStatus = 'Successfully authenticated!';
          _saveAuthenticationState(true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          _authenticationStatus =
              'Biometric login successful, but no Firebase user found. Please log in manually.';
        }
      } else {
        _authenticationStatus = 'Authentication failed. Please try again.';
        _saveAuthenticationState(false);
      }
    } catch (e) {
      print("Error: $e");
      _authenticationStatus = 'An error occurred during authentication';
      _saveAuthenticationState(false);
    }

    setState(() {
      _isAuthenticated = authenticated;
      _isProcessing = false;
    });
  }

  Future<void> _saveAuthenticationState(bool isAuthenticated) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isAuthenticated', isAuthenticated);
  }

  Future<void> _saveCredentials() async {
    try {
      await storage.write(key: 'username', value: _emailController.text);
      await storage.write(key: 'password', value: _passwordController.text);

      final user = _auth.currentUser;
      if (user != null) {
        await storage.write(key: 'firebase_email', value: user.email);
        await storage.write(key: 'uid', value: user.uid);
      }

      setState(() {
        _isRegistered = true;
      });
    } catch (e) {
      print("Error saving credentials: $e");
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!EmailValidator.validate(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => stateOnlyCustomIndicatorText = ButtonState.loading);

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        setState(() => stateOnlyCustomIndicatorText = ButtonState.success);
        await _saveCredentials();
        _saveAuthenticationState(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException {
      print("Firebase login failed, checking local storage...");

      final savedEmail = await storage.read(key: 'username');
      final savedPassword = await storage.read(key: 'password');

      if (savedEmail == email && savedPassword == password) {
        setState(() => stateOnlyCustomIndicatorText = ButtonState.success);
        _saveAuthenticationState(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() => stateOnlyCustomIndicatorText = ButtonState.fail);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Check credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() => googleSignInButtonState = ButtonState.loading);
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => googleSignInButtonState = ButtonState.fail);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        setState(() => googleSignInButtonState = ButtonState.success);
        _saveCredentials();
        _saveAuthenticationState(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => googleSignInButtonState = ButtonState.fail);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRegistered && !_isAuthenticated) {
      if (_biometricSupported) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _authenticate();
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                touchX = details.localPosition.dx;
                touchY = details.localPosition.dy;
                isTouched = true;
              });
            },
            onPanEnd: (_) {
              setState(() {
                isTouched = false;
              });
            },
            child: AnimatedBackground(
              animation: _animationController,
              touchX: touchX,
              touchY: touchY,
              isTouched: isTouched,
            ),
          ),
          Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isAuthenticated)
                    Column(
                      children: [
                        CustomTextField(
                          labelText: 'Username',
                          hintText: 'Enter your username',
                          obscureText: false,
                          controller: _emailController,
                          onChanged: (text) {},
                          validator: (text) {
                            if (text!.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        CustomTextField(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          obscureText: true,
                          controller: _passwordController,
                          onChanged: (text) {},
                          validator: (text) {
                            if (text!.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomeScreen()),
                            );
                          },
                          child: const Text('Sign Up'),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () async {
                            await signInWithGoogle();
                          },
                          child: const Text('google'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()),
                            );
                          },
                          child: const Text('Sign Up'),
                        ),
                        const SizedBox(height: 15),
                        if (_biometricSupported)
                          Column(
                            children: [
                              const SizedBox(height: 15),
                              TextButton(
                                onPressed: _authenticate,
                                child: const Text('Login with Fingerprint'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  if (_isAuthenticated)
                    Column(
                      children: [
                        const Text('Welcome back!'),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isAuthenticated = false;
                              _authenticationStatus = 'Not Authenticated';
                            });
                            _saveAuthenticationState(false);
                            storage.deleteAll();
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Text(_authenticationStatus),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
