import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import 'base_service.dart';

class EquipmentService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResult<Map<String, dynamic>>> getLiveRent({
    required String equipmentName,
    required String district,
    required String state,
  }) async {
    try {
      final response = await _client.postJson(
        '/equipment-sharing/api/get-live-rent',
        <String, dynamic>{
          'equipment_name': equipmentName,
          'district': district,
          'state': state,
        },
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }
      return ApiResult.failure(
        (body['error'] ?? 'Rent not available').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<void>> createListing(Map<String, dynamic> data) async {
    try {
      final response = await _client.postForm(
        '/equipment-sharing/create-listing',
        data,
        followRedirects: false,
      );
      if ((response.statusCode ?? 500) < 400) {
        return ApiResult.success(null);
      }
      return ApiResult.failure('Failed to create equipment listing');
    } catch (error) {
      return failureFromError<void>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> confirmRental(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _client.postJson(
        '/equipment-sharing/api/confirm-rental',
        payload,
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }
      return ApiResult.failure(
        (body['error'] ?? 'Rental booking failed').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> cancelListing(
    String listingId,
  ) async {
    try {
      final response = await _client.postJson(
        '/equipment-sharing/api/cancel-listing/$listingId',
        <String, dynamic>{},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }
      return ApiResult.failure(
        (body['error'] ?? 'Failed to cancel listing').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> completeRental(
    String listingId,
  ) async {
    try {
      final response = await _client.postJson(
        '/equipment-sharing/api/complete-rental/$listingId',
        <String, dynamic>{},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }
      return ApiResult.failure(
        (body['error'] ?? 'Failed to complete rental').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<String>> loadMarketplaceHtml() async {
    try {
      final response = await _client.get('/equipment-sharing/marketplace');
      return ApiResult.success(parseBody(response).toString());
    } catch (error) {
      return failureFromError<String>(error);
    }
  }
}
