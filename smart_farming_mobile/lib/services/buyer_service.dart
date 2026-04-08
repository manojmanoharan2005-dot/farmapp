import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import 'base_service.dart';

class BuyerService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResult<Map<String, dynamic>>> getLivePrice({
    required String crop,
    required String district,
    required String state,
  }) async {
    try {
      final response = await _client.postJson(
        '/buyer-connect/api/get-live-price',
        <String, dynamic>{'crop': crop, 'district': district, 'state': state},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }
      return ApiResult.failure(
        (body['error'] ?? 'Price not available').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<void>> createListing(Map<String, dynamic> data) async {
    try {
      final response = await _client.postForm(
        '/buyer-connect/create-listing',
        data,
        followRedirects: false,
      );
      if ((response.statusCode ?? 500) < 400) {
        return ApiResult.success(null);
      }
      return ApiResult.failure('Failed to create listing');
    } catch (error) {
      return failureFromError<void>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> confirmPurchase({
    required String listingId,
    required String buyerName,
    required String buyerPhone,
  }) async {
    try {
      final response = await _client.postJson(
        '/buyer-connect/api/confirm-purchase',
        <String, dynamic>{
          'listing_id': listingId,
          'buyer_name': buyerName,
          'buyer_phone': buyerPhone,
        },
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }
      return ApiResult.failure((body['error'] ?? 'Purchase failed').toString());
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> cancelListing(
    String listingId,
  ) async {
    try {
      final response = await _client.postJson(
        '/buyer-connect/api/cancel-listing/$listingId',
        <String, dynamic>{},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }
      return ApiResult.failure((body['error'] ?? 'Cancel failed').toString());
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<String>> loadMarketplaceHtml() async {
    try {
      final response = await _client.get('/buyer-connect/marketplace');
      final body = parseBody(response).toString();
      return ApiResult.success(body);
    } catch (error) {
      return failureFromError<String>(error);
    }
  }
}
