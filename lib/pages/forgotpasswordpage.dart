import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore queries
import 'package:flutter/material.dart';
import 'package:sangy/components/my_button.dart';
import 'package:sangy/components/my_textfield.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailOrUsernameController = TextEditingController(); // Controller for email or username

  // Method to handle password reset
  void sendResetEmail() async {
    String input = emailOrUsernameController.text;

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email or username')),
      );
      return;
    }

    // Check if the input is a valid email using regex
    bool isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input);

    try {
      String email = input;

      // If the input is not an email, assume it's a username and fetch the associated email
      if (!isEmail) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (userSnapshot.docs.isEmpty) {
          throw Exception('No user found with this username.');
        }

        // Retrieve the associated email from Firestore
        email = userSnapshot.docs.first.get('email');
      }

      // Send the password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Please check your inbox.'),
        ),
      );

      // Optionally redirect to a confirmation page or login page
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter your email or username to reset password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              MyTextField(
                controller: emailOrUsernameController,
                hintText: 'Email or Username',
                obscureText: false,
              ),
              const SizedBox(height: 25),
              MyButton(
                onTap: sendResetEmail,
                text: "Send Reset Email",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
