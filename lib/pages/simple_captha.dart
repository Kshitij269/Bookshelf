import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sangy/components/my_textfield.dart';

class SimpleCaptcha extends StatefulWidget {
  final Function(String) onVerify;

  SimpleCaptcha({required this.onVerify});

  @override
  _SimpleCaptchaState createState() => _SimpleCaptchaState();
}

class _SimpleCaptchaState extends State<SimpleCaptcha> {
  String captchaText = '';
  final TextEditingController _captchaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    generateCaptcha();
  }

  void generateCaptcha() {
    final random = Random();
    final letters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    captchaText =
        List.generate(6, (index) => letters[random.nextInt(letters.length)])
            .join('');
    setState(() {});
  }

  void verifyCaptcha() {
    if (_captchaController.text == captchaText) {
      widget.onVerify(captchaText); // Call the onVerify function
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('CAPTCHA verification failed. Please try again.')),
      );
      generateCaptcha(); // Regenerate CAPTCHA if verification fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 25.0, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                captchaText,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: generateCaptcha,
                color: Colors.blue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        MyTextField(
          controller: _captchaController,
          hintText: 'Captcha',
          obscureText: false,
        ),
        const SizedBox(height: 10),
        Center(
          child: ElevatedButton(
            onPressed: verifyCaptcha,
            child: const Text('Verify'),
            style: ElevatedButton.styleFrom(
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _captchaController.dispose();
    super.dispose();
  }
}
