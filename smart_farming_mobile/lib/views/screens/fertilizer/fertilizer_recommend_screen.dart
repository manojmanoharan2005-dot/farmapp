import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/fertilizer_controller.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_card.dart';

class FertilizerRecommendScreen extends StatefulWidget {
  const FertilizerRecommendScreen({super.key});

  @override
  State<FertilizerRecommendScreen> createState() =>
      _FertilizerRecommendScreenState();
}

class _FertilizerRecommendScreenState extends State<FertilizerRecommendScreen> {
  final _crop = TextEditingController(text: 'Rice');
  final _n = TextEditingController(text: '70');
  final _p = TextEditingController(text: '30');
  final _k = TextEditingController(text: '25');
  final _moisture = TextEditingController(text: '55');

  @override
  void dispose() {
    _crop.dispose();
    _n.dispose();
    _p.dispose();
    _k.dispose();
    _moisture.dispose();
    super.dispose();
  }

  void _generate() {
    context.read<FertilizerController>().generateRecommendations(
      crop: _crop.text.trim(),
      nitrogen: double.tryParse(_n.text.trim()) ?? 0,
      phosphorus: double.tryParse(_p.text.trim()) ?? 0,
      potassium: double.tryParse(_k.text.trim()) ?? 0,
      moisture: double.tryParse(_moisture.text.trim()) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FertilizerController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Fertilizer Recommend')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (controller.errorMessage != null)
                  ErrorBanner(message: controller.errorMessage!),
                SectionCard(
                  title: 'Input Values',
                  child: Column(
                    children: <Widget>[
                      AppTextField(controller: _crop, label: 'Crop'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _n,
                        label: 'Nitrogen',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _p,
                        label: 'Phosphorus',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _k,
                        label: 'Potassium',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _moisture,
                        label: 'Soil Moisture (%)',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Generate Recommendations',
                        onPressed: _generate,
                      ),
                    ],
                  ),
                ),
                if (controller.recommendations.isNotEmpty)
                  SectionCard(
                    title: 'Recommendations',
                    child: Column(
                      children: controller.recommendations.map((item) {
                        return Card(
                          child: ListTile(
                            title: Text(item['name'].toString()),
                            subtitle: Text(
                              '${item['dosage']} | Confidence: ${item['confidence']}%',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.save_alt),
                              onPressed: () =>
                                  controller.saveRecommendation(item),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
