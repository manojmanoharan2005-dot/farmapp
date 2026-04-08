import '../services/fertilizer_service.dart';
import 'base_controller.dart';

class FertilizerController extends BaseController {
  final FertilizerService _service;

  FertilizerController(this._service);

  List<Map<String, dynamic>> recommendations = <Map<String, dynamic>>[];

  void generateRecommendations({
    required String crop,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double moisture,
  }) {
    clearMessages();
    recommendations = _service.recommendLocally(
      crop: crop,
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      moisture: moisture,
    );

    if (recommendations.isEmpty) {
      setError('No recommendations found');
      return;
    }

    setSuccess('Recommendations generated');
    notifyListeners();
  }

  Future<void> saveRecommendation(Map<String, dynamic> recommendation) async {
    setLoading(true);
    final result = await _service.saveRecommendation(recommendation);
    setLoading(false);

    if (result.isSuccess) {
      setSuccess('Recommendation saved to backend');
    } else {
      setError(result.error ?? 'Save failed');
    }
  }
}
