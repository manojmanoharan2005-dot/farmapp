import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import 'base_service.dart';

class DashboardService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResult<Map<String, dynamic>>> fetchWeather() async {
    try {
      final response = await _client.get('/api/weather-update');
      final body = asMap(parseBody(response));

      if (response.statusCode == 200 && body.isNotEmpty) {
        return ApiResult.success(body);
      }

      return ApiResult.failure(
        (body['error'] ?? 'Unable to load weather').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> markNotificationsRead() async {
    try {
      final response = await _client.postJson(
        '/mark-notifications-read',
        <String, dynamic>{},
      );
      return ApiResult.success(asMap(parseBody(response)));
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> fetchReportsSnapshot() async {
    try {
      final crop = await _client.get('/api/report/crop-plan');
      final profit = await _client.get('/api/report/profit');
      final market = await _client.get('/api/report/market-watch');

      return ApiResult.success(<String, dynamic>{
        'crop_plan': asMap(parseBody(crop)),
        'profit': asMap(parseBody(profit)),
        'market': asMap(parseBody(market)),
      });
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }
}
