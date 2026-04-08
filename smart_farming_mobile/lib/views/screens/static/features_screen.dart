import 'package:flutter/material.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const features = <String>[
      'Authentication with OTP and forgot-password flow',
      'AI Crop Suggestion and start-growing planner',
      'Fertilizer recommendation and save flow',
      'Market Watch with live prices and trend lookup',
      'Buyer marketplace and crop listing actions',
      'Equipment sharing listing and rental actions',
      'Regional calendar generation by district and soil type',
      'AI chat assistant for farming questions',
      'Report dashboards and PDF exports',
      'Responsive Android-friendly navigation with drawer and bottom tabs',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Features')),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: features.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(features[index]),
            );
          },
        ),
      ),
    );
  }
}
