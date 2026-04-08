import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import 'base_service.dart';

class ResourcesService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResult<Map<String, dynamic>>> generateRegionalCalendar({
    required String state,
    required String district,
    required String soilType,
    String previousCrops = '',
  }) async {
    try {
      final response = await _client
          .postJson('/resources/calendar', <String, dynamic>{
            'state': state,
            'district': district,
            'soil_type': soilType,
            'previous_crops': previousCrops,
          });

      final body = asMap(parseBody(response));
      if ((body['success'] ?? false) == true) {
        return ApiResult.success(asMap(body['data']));
      }

      return ApiResult.failure(
        (body['error'] ?? body['message'] ?? 'Could not generate calendar')
            .toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }
}
