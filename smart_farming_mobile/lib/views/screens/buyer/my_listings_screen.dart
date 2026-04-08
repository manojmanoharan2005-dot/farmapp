import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Crop Listings')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: FeaturePlaceholder(
            title: 'My Listings View',
            description:
                'The backend currently serves My Listings as rendered HTML. This mobile screen is reserved for the same feature and can be fully populated once a JSON list endpoint is exposed.',
          ),
        ),
      ),
    );
  }
}
