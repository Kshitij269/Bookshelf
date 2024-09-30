import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore queries
import 'package:flutter/material.dart';
import 'package:sangy/components/my_button.dart';
import 'package:sangy/components/my_textfield.dart';
import 'package:sangy/pages/forgotpasswordpage.dart';
import 'package:sangy/pages/home_page.dart';
import 'package:sangy/pages/registerpage.dart';
import 'package:sangy/pages/simple_captha.dart'; // Import your SimpleCaptcha widget

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Text editing controllers
  final emailOrUsernameController = TextEditingController(); // Updated to handle both email and username
  final passwordController = TextEditingController();

  // CAPTCHA verification status
  bool captchaVerified = false;

  // Method to handle CAPTCHA verification
  void onCaptchaVerify(String captchaText) {
    setState(() {
      captchaVerified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CAPTCHA verified! You can now log in.')),
    );
  }

  // Sign user in method
  void signUserIn() async {
    if (!captchaVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please verify the CAPTCHA before logging in.')),
      );
      return;
    }

    // Show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      String email = emailOrUsernameController.text;

      // Check if input is a valid email
      bool isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);

      // If it's not an email, assume it's a username and fetch the associated email
      if (!isEmail) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: email)
            .limit(1)
            .get();

        if (userSnapshot.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with this username.',
          );
        }

        email = userSnapshot.docs.first.get('email'); // Retrieve email from the query result
      }

      // Proceed with Firebase authentication using the email (from input or Firestore)
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );

      User? user = userCredential.user;

      // Check if the email is verified
      if (user != null && !user.emailVerified) {
        Navigator.pop(context); // Close the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email before logging in.'),
          ),
        );
        await user.sendEmailVerification();
      } else {
        // User signed in successfully
        Navigator.pop(context); // Close the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User Signed In')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close the loading dialog
      if (e.code == 'wrong-password') {
        wrongPasswordMessage();
      } else if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please check your credentials.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  // Forgot password method (Unchanged)
  void forgotPassword() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
    );
  }

  // Wrong password message popup
  void wrongPasswordMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid Credentials')),
    );
  }

  @override
  void dispose() {
    emailOrUsernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[300],
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'BOOKSHELF',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: Colors.black,
                  fontSize: 33,
                ),
              ),
              const SizedBox(height: 30),
              const Icon(
                Icons.lock,
                size: 100,
              ),
              const SizedBox(height: 50),
              Text(
                'Welcome back, you\'ve been missed!',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 25),

              // Email or Username text field
              MyTextField(
                controller: emailOrUsernameController,
                hintText: 'Email or Username',
                obscureText: false,
              ),

              const SizedBox(height: 10),

              // Password text field
              MyTextField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),

              const SizedBox(height: 10),

              // Forgot password link
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: forgotPassword, // Unchanged Forgot Password functionality
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // Simple CAPTCHA widget
              SimpleCaptcha(onVerify: onCaptchaVerify), // Ensure this widget is defined

              const SizedBox(height: 10),

              // Sign in button
              MyButton(
                onTap: signUserIn,
                text: "Login User",
              ),

              const SizedBox(height: 20),

              // Not a member? Register now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not a member?',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      );
                    },
                    child: const Text(
                      'Register now',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
