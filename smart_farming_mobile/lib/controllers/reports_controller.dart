import 'package:url_launcher/url_launcher.dart';

import '../services/report_service.dart';
import 'base_controller.dart';

class ReportsController extends BaseController {
  final ReportService _service;

  ReportsController(this._service);

  Map<String, dynamic> cropPlan = <String, dynamic>{};
  Map<String, dynamic> harvest = <String, dynamic>{};
  Map<String, dynamic> profit = <String, dynamic>{};
  Map<String, dynamic> market = <String, dynamic>{};
  Map<String, dynamic> weather = <String, dynamic>{};

  Future<void> loadReports() async {
    setLoading(true);
    clearMessages();

    final cropResult = await _service.cropPlan();
    final harvestResult = await _service.harvest();
    final profitResult = await _service.profit();
    final marketResult = await _service.marketWatch();
    final weatherResult = await _service.weather();

    if (cropResult.isSuccess) {
      cropPlan = cropResult.data ?? <String, dynamic>{};
    }
    if (harvestResult.isSuccess) {
      harvest = harvestResult.data ?? <String, dynamic>{};
    }
    if (profitResult.isSuccess) {
      profit = profitResult.data ?? <String, dynamic>{};
    }
    if (marketResult.isSuccess) {
      market = marketResult.data ?? <String, dynamic>{};
    }
    if (weatherResult.isSuccess) {
      weather = weatherResult.data ?? <String, dynamic>{};
    }

    final failures = <String?>[
      cropResult.error,
      harvestResult.error,
      profitResult.error,
      marketResult.error,
      weatherResult.error,
    ].whereType<String>().toList();

    if (failures.isNotEmpty) {
      setError(failures.first);
    }

    setLoading(false);
  }

  Future<void> openUrl(String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      setError('Unable to open report link');
    }
  }

  String get marketPdfUrl => _service.marketPdfUrl;
  String get weatherPdfUrl => _service.weatherPdfUrl;
  String get expensePdfUrl => _service.expensePdfUrl;
  String get cropProgressPdfUrl => _service.cropProgressPdfUrl;
}
