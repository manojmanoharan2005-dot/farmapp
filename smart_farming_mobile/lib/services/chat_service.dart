import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import 'base_service.dart';

class ChatService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResult<String>> sendMessage(String message) async {
    try {
      final response = await _client.postJson(
        '/chat/message',
        <String, dynamic>{'message': message},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success((body['response'] ?? '').toString());
      }

      return ApiResult.failure(
        (body['error'] ?? 'Chat service unavailable').toString(),
      );
    } catch (error) {
      return failureFromError<String>(error);
    }
  }
}
