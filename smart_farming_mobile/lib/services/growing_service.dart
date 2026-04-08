import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import 'base_service.dart';

class GrowingService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResult<List<Map<String, dynamic>>>> fetchActivities() async {
    try {
      final response = await _client.get('/api/report/crop-plan');
      final body = asMap(parseBody(response));
      if ((body['success'] ?? false) == true) {
        final data = asMap(body['data']);
        return ApiResult.success(asListOfMap(data['crops']));
      }
      return ApiResult.failure(
        (body['message'] ?? 'No activities found').toString(),
      );
    } catch (error) {
      return failureFromError<List<Map<String, dynamic>>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> fetchHarvestSummary() async {
    try {
      final response = await _client.get('/api/report/harvest');
      final body = asMap(parseBody(response));
      if ((body['success'] ?? false) == true) {
        return ApiResult.success(asMap(body['data']));
      }
      return ApiResult.failure(
        (body['message'] ?? 'No harvest data').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> updateActivity({
    required String activityId,
    String? stage,
    String? notes,
    List<int>? completedTasks,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (stage != null) payload['stage'] = stage;
      if (notes != null) payload['notes'] = notes;
      if (completedTasks != null) payload['tasks'] = completedTasks;

      final response = await _client.postJson(
        '/growing/update/$activityId',
        payload,
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }
      return ApiResult.failure((body['message'] ?? 'Update failed').toString());
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> completeTask({
    required String activityId,
    required int taskIndex,
  }) async {
    try {
      final response = await _client.postForm(
        '/growing/task/complete',
        <String, dynamic>{
          'activity_id': activityId,
          'task_index': taskIndex.toString(),
        },
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }

      return ApiResult.failure(
        (body['message'] ?? 'Failed to complete task').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> deleteActivity(
    String activityId,
  ) async {
    try {
      final response = await _client.postForm(
        '/growing/delete/$activityId',
        <String, dynamic>{},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }
      return ApiResult.failure((body['message'] ?? 'Delete failed').toString());
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> saveExpense(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _client.postJson('/api/expenses', payload);
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }

      return ApiResult.failure(
        (body['message'] ?? 'Failed to save expense').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }
}
