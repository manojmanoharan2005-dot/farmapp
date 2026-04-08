import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class EquipmentMyListingsScreen extends StatelessWidget {
  const EquipmentMyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment My Listings')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: FeaturePlaceholder(
            title: 'My Equipment Listings',
            description:
                'This page is mapped from equipment_my_listings.html. Data can be switched to native cards once a JSON listing endpoint is added.',
          ),
        ),
      ),
    );
  }
}
