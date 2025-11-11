import 'package:flutter/material.dart';

/// Minimal placeholder auth screen. Replace with real auth UI in Task 7.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to PlantCare.ID',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Continue as guest -> navigate to home
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text('Continue as Guest'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // Placeholder for real login flow
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
