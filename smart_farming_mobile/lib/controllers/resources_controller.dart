import '../services/resources_service.dart';
import 'base_controller.dart';

class ResourcesController extends BaseController {
  final ResourcesService _service;

  ResourcesController(this._service);

  Map<String, dynamic> calendarData = <String, dynamic>{};

  Future<void> generateCalendar({
    required String state,
    required String district,
    required String soilType,
    String previousCrops = '',
  }) async {
    setLoading(true);
    clearMessages();

    final result = await _service.generateRegionalCalendar(
      state: state,
      district: district,
      soilType: soilType,
      previousCrops: previousCrops,
    );

    setLoading(false);

    if (result.isSuccess) {
      calendarData = result.data ?? <String, dynamic>{};
      notifyListeners();
      return;
    }

    setError(result.error ?? 'Unable to generate calendar');
  }
}
