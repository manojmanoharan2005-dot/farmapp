import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/crop_controller.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';

class StartGrowingScreen extends StatefulWidget {
  const StartGrowingScreen({super.key});

  @override
  State<StartGrowingScreen> createState() => _StartGrowingScreenState();
}

class _StartGrowingScreenState extends State<StartGrowingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _startDateController = TextEditingController();
  final _harvestDateController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _cropController.text = (args['crop'] ?? '').toString();
    }

    if (_startDateController.text.isEmpty) {
      final now = DateTime.now();
      final harvest = now.add(const Duration(days: 90));
      _startDateController.text = now.toIso8601String().substring(0, 10);
      _harvestDateController.text = harvest.toIso8601String().substring(0, 10);
    }
  }

  @override
  void dispose() {
    _cropController.dispose();
    _startDateController.dispose();
    _harvestDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<CropController>();
    await controller.saveGrowingPlan(
      cropName: _cropController.text.trim(),
      startDate: _startDateController.text.trim(),
      harvestDate: _harvestDateController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    if (controller.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Growing plan saved. Check Growing Activities.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CropController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Start Growing')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    if (controller.errorMessage != null)
                      ErrorBanner(message: controller.errorMessage!),
                    AppTextField(
                      controller: _cropController,
                      label: 'Crop name',
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: _startDateController,
                      label: 'Start date (YYYY-MM-DD)',
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: _harvestDateController,
                      label: 'Harvest date (YYYY-MM-DD)',
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: _notesController,
                      label: 'Notes',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Save Growing Plan',
                      isLoading: controller.isLoading,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
