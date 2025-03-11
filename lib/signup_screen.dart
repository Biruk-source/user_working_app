import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:email_validator/email_validator.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final storage = const FlutterSecureStorage();

  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Create Your Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildEmailField(),
                const SizedBox(height: 15),
                _buildPasswordField(),
                const SizedBox(height: 20),
                _buildSignUpButton(),
                const SizedBox(height: 15),
                _buildGoogleSignInButton(),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please enter your email';
        }
        if (!EmailValidator.validate(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _isProcessing
          ? null
          : () async {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _isProcessing = true;
                });
                try {
                  final userCredential =
                      await _auth.createUserWithEmailAndPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );

                  if (userCredential.user != null) {
                    await storage.write(
                      key: 'username',
                      value: _emailController.text,
                    );
                    await storage.write(
                      key: 'password',
                      value: _passwordController.text,
                    );
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setBool('isAuthenticated', true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  setState(() {
                    _isProcessing = false;
                  });
                  String errorMessage = 'Sign up failed';
                  switch (e.code) {
                    case 'weak-password':
                      errorMessage = 'The password provided is too weak.';
                      break;
                    case 'email-already-in-use':
                      errorMessage =
                          'An account already exists for this email.';
                      break;
                    default:
                      errorMessage =
                          e.message ?? 'An error occurred during sign up.';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  setState(() {
                    _isProcessing = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('An unexpected error occurred.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
      child: const Text('Sign Up'),
    );
  }

  Widget _buildGoogleSignInButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: _isProcessing
          ? null
          : () async {
              setState(() {
                _isProcessing = true;
              });
              try {
                final GoogleSignInAccount? googleUser =
                    await _googleSignIn.signIn();
                if (googleUser == null) {
                  setState(() {
                    _isProcessing = false;
                  });
                  return;
                }

                final GoogleSignInAuthentication googleAuth =
                    await googleUser.authentication;
                final credential = GoogleAuthProvider.credential(
                  accessToken: googleAuth.accessToken,
                  idToken: googleAuth.idToken,
                );

                final userCredential =
                    await _auth.signInWithCredential(credential);

                if (userCredential.user != null) {
                  await storage.write(
                    key: 'username',
                    value: userCredential.user!.email,
                  );
                  await storage.write(
                    key: 'password',
                    value: 'google_sign_in',
                  );
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setBool('isAuthenticated', true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Account created successfully with Google!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }
              } catch (e) {
                setState(() {
                  _isProcessing = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Google Sign-In failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
      child: const Text('Sign Up with Google'),
    );
  }
}
