import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BiometricPromptDialog extends StatelessWidget {
  final VoidCallback onAccept;
  
  const BiometricPromptDialog({
    super.key,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Enable Biometric Login',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/animations/fingerprint.json',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 16),
          const Text(
            'Would you like to use your fingerprint for future logins?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Not Now',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            onAccept();
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Enable'),
        ),
      ],
    );
  }
}
