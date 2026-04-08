import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class EquipmentRentalHistoryScreen extends StatelessWidget {
  const EquipmentRentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment Rental History')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: FeaturePlaceholder(
            title: 'Rental History',
            description:
                'This screen maps equipment_rental_history.html. Booking completion/cancel APIs are already integrated in services for action flows.',
          ),
        ),
      ),
    );
  }
}
