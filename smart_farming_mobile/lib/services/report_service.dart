import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import 'base_service.dart';

class ReportService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResult<Map<String, dynamic>>> cropPlan() =>
      _getReport('/api/report/crop-plan');

  Future<ApiResult<Map<String, dynamic>>> harvest() =>
      _getReport('/api/report/harvest');

  Future<ApiResult<Map<String, dynamic>>> profit() =>
      _getReport('/api/report/profit');

  Future<ApiResult<Map<String, dynamic>>> marketWatch() =>
      _getReport('/api/report/market-watch');

  Future<ApiResult<Map<String, dynamic>>> weather() =>
      _getReport('/api/report/weather');

  Future<ApiResult<Map<String, dynamic>>> _getReport(String endpoint) async {
    try {
      final response = await _client.get(endpoint);
      final body = asMap(parseBody(response));
      if ((body['success'] ?? false) == true) {
        return ApiResult.success(asMap(body['data']));
      }

      return ApiResult.failure(
        (body['message'] ?? 'Report unavailable').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  String get marketPdfUrl => '${AppConfig.baseUrl}/download/market-prices-pdf';
  String get weatherPdfUrl => '${AppConfig.baseUrl}/download/weather-pdf';
  String get expensePdfUrl => '${AppConfig.baseUrl}/download/expense-pdf';
  String get cropProgressPdfUrl =>
      '${AppConfig.baseUrl}/download/crop-progress-pdf';
}
