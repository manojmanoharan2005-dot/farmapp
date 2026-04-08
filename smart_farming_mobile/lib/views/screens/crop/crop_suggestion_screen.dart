import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/crop_controller.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_card.dart';

class CropSuggestionScreen extends StatefulWidget {
  const CropSuggestionScreen({super.key});

  @override
  State<CropSuggestionScreen> createState() => _CropSuggestionScreenState();
}

class _CropSuggestionScreenState extends State<CropSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _n = TextEditingController(text: '90');
  final _p = TextEditingController(text: '40');
  final _k = TextEditingController(text: '40');
  final _temperature = TextEditingController(text: '26');
  final _humidity = TextEditingController(text: '75');
  final _ph = TextEditingController(text: '6.5');
  final _rainfall = TextEditingController(text: '120');

  @override
  void dispose() {
    _n.dispose();
    _p.dispose();
    _k.dispose();
    _temperature.dispose();
    _humidity.dispose();
    _ph.dispose();
    _rainfall.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<CropController>().predict(
      nitrogen: double.parse(_n.text.trim()),
      phosphorus: double.parse(_p.text.trim()),
      potassium: double.parse(_k.text.trim()),
      temperature: double.parse(_temperature.text.trim()),
      humidity: double.parse(_humidity.text.trim()),
      ph: double.parse(_ph.text.trim()),
      rainfall: double.parse(_rainfall.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CropController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Crop Suggestion')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (controller.errorMessage != null)
                    ErrorBanner(message: controller.errorMessage!),
                  SectionCard(
                    title: 'Soil & Weather Inputs',
                    child: Column(
                      children: <Widget>[
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
                          controller: _temperature,
                          label: 'Temperature (C)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _humidity,
                          label: 'Humidity (%)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _ph,
                          label: 'pH',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _rainfall,
                          label: 'Rainfall (mm)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Predict Crops',
                          isLoading: controller.isLoading,
                          onPressed: _predict,
                        ),
                      ],
                    ),
                  ),
                  if (controller.isLoading)
                    const LoadingState(label: 'Predicting...'),
                  if (controller.predictions.isNotEmpty)
                    SectionCard(
                      title: 'Top Recommendations',
                      child: Column(
                        children: controller.predictions.take(5).map((item) {
                          final crop =
                              (item['name'] ?? item['crop'] ?? 'Unknown')
                                  .toString();
                          final score =
                              item['confidence_percentage'] ??
                              item['probability'] ??
                              0;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(crop),
                            subtitle: Text('Suitability: $score'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.startGrowing,
                                  arguments: <String, dynamic>{
                                    'crop': crop,
                                    'probability': score.toString(),
                                  },
                                );
                              },
                              child: const Text('Start'),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
