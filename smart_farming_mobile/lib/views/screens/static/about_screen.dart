import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Smart Farming Assistant helps farmers with crop planning, fertilizer advice, market intelligence, buyer connections, equipment sharing, and report generation.\n\nThis Flutter app is the mobile conversion of the web platform and connects directly to the same backend.',
          ),
        ),
      ),
    );
  }
}
