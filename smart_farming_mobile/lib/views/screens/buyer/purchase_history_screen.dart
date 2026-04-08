import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase History')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: FeaturePlaceholder(
            title: 'Purchase History',
            description:
                'Purchase history is available in backend HTML templates. The screen is created and ready for JSON integration without changing your app navigation.',
          ),
        ),
      ),
    );
  }
}
