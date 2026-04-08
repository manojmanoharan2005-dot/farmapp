import '../services/crop_service.dart';
import 'base_controller.dart';

class CropController extends BaseController {
  final CropService _service;

  CropController(this._service);

  List<Map<String, dynamic>> predictions = <Map<String, dynamic>>[];
  String diseaseResult = '';

  Future<void> predict({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double ph,
    required double rainfall,
  }) async {
    setLoading(true);
    clearMessages();

    final result = await _service.predictCrop(
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      temperature: temperature,
      humidity: humidity,
      ph: ph,
      rainfall: rainfall,
    );

    setLoading(false);

    if (result.isSuccess) {
      final body = result.data ?? <String, dynamic>{};
      final data = body['data'];
      if (data is Map && data['recommendations'] is List) {
        predictions = (data['recommendations'] as List)
            .whereType<Map>()
            .map((Map e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (data is Map && data['top_predictions'] is List) {
        predictions = (data['top_predictions'] as List)
            .whereType<Map>()
            .map((Map e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (predictions.isEmpty) {
        setError('No recommendations returned');
      }
      notifyListeners();
      return;
    }

    setError(result.error ?? 'Crop prediction failed');
  }

  Future<void> saveGrowingPlan({
    required String cropName,
    required String startDate,
    required String harvestDate,
    String notes = '',
  }) async {
    setLoading(true);
    clearMessages();

    final result = await _service.saveGrowingPlan(
      cropName: cropName,
      startDate: startDate,
      harvestDate: harvestDate,
      notes: notes,
    );

    setLoading(false);

    if (result.isSuccess) {
      setSuccess('Growing plan saved');
    } else {
      setError(result.error ?? 'Failed to save plan');
    }
  }

  Future<void> detectDisease(String imagePath) async {
    setLoading(true);
    clearMessages();

    final result = await _service.detectDisease(imagePath: imagePath);

    setLoading(false);
    if (result.isSuccess) {
      diseaseResult = (result.data?['result'] ?? 'Image submitted successfully')
          .toString();
      notifyListeners();
    } else {
      setError(result.error ?? 'Disease detection failed');
    }
  }
}
