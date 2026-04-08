import '../services/dashboard_service.dart';
import 'base_controller.dart';

class DashboardController extends BaseController {
  final DashboardService _service;

  DashboardController(this._service);

  Map<String, dynamic> weather = <String, dynamic>{};
  Map<String, dynamic> snapshot = <String, dynamic>{};

  Future<void> loadDashboard() async {
    setLoading(true);
    clearMessages();

    final weatherResult = await _service.fetchWeather();
    final snapshotResult = await _service.fetchReportsSnapshot();

    if (weatherResult.isSuccess) {
      weather = weatherResult.data ?? <String, dynamic>{};
    } else {
      setError(weatherResult.error);
    }

    if (snapshotResult.isSuccess) {
      snapshot = snapshotResult.data ?? <String, dynamic>{};
    }

    setLoading(false);
  }

  Future<void> markNotificationsRead() async {
    final result = await _service.markNotificationsRead();
    if (!result.isSuccess) {
      setError(result.error);
    } else {
      setSuccess('Notifications marked as read');
    }
  }
}
