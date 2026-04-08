import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/growing_controller.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';

class GrowingViewScreen extends StatefulWidget {
  const GrowingViewScreen({super.key});

  @override
  State<GrowingViewScreen> createState() => _GrowingViewScreenState();
}

class _GrowingViewScreenState extends State<GrowingViewScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final activity = args is Map<String, dynamic> ? args : <String, dynamic>{};

    final activityId = (activity['id'] ?? activity['_id'] ?? '').toString();
    final crop = (activity['crop'] ?? activity['crop_name'] ?? 'Unknown')
        .toString();
    final notes = (activity['notes'] ?? '').toString();
    if (_notesController.text.isEmpty) {
      _notesController.text = notes;
    }

    return Consumer<GrowingController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: Text('$crop Activity')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (controller.errorMessage != null)
                  ErrorBanner(message: controller.errorMessage!),
                Text(
                  'Crop: $crop',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Stage: ${(activity['stage'] ?? activity['current_stage'] ?? 'Unknown')}',
                ),
                Text('Progress: ${(activity['progress'] ?? 0)}%'),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Update Notes',
                  isLoading: controller.isLoading,
                  onPressed: activityId.isEmpty
                      ? null
                      : () => controller.updateNotes(
                          activityId,
                          _notesController.text.trim(),
                        ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: activityId.isEmpty
                      ? null
                      : () => controller.deleteActivity(activityId),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Activity'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
