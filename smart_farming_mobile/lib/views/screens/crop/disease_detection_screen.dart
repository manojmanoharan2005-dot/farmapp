import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../controllers/crop_controller.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_card.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  String? _imagePath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _imagePath = image.path);
  }

  Future<void> _analyze() async {
    if (_imagePath == null) return;
    await context.read<CropController>().detectDisease(_imagePath!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CropController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Disease Detection')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (controller.errorMessage != null)
                  ErrorBanner(message: controller.errorMessage!),
                SectionCard(
                  title: 'Upload Leaf/Crop Image',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_imagePath == null)
                        const Text('No image selected')
                      else
                        Text('Selected: $_imagePath'),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose Image'),
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: 'Analyze Disease',
                        isLoading: controller.isLoading,
                        onPressed: _imagePath == null ? null : _analyze,
                      ),
                    ],
                  ),
                ),
                if (controller.diseaseResult.isNotEmpty)
                  SectionCard(
                    title: 'Detection Result',
                    child: Text(controller.diseaseResult),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
