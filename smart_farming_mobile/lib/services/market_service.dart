import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import '../models/market_record.dart';
import 'base_service.dart';

class MarketService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResult<List<MarketRecord>>> refreshPrices({String? state}) async {
    try {
      final response = await _client.get(
        '/api/refresh-prices',
        queryParameters: <String, dynamic>{
          if (state != null && state.isNotEmpty) 'state': state,
        },
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        final records = asListOfMap(
          body['data'],
        ).map(MarketRecord.fromMap).toList();
        return ApiResult.success(records);
      }

      return ApiResult.failure(
        (body['error'] ?? 'Unable to load market data').toString(),
      );
    } catch (error) {
      return failureFromError<List<MarketRecord>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> nearbyMandis({
    required double lat,
    required double lon,
    double radius = 50,
  }) async {
    try {
      final response = await _client.get(
        '/api/nearby-mandis',
        queryParameters: <String, dynamic>{
          'lat': lat,
          'lon': lon,
          'radius': radius,
        },
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }

      return ApiResult.failure(
        (body['error'] ?? body['message'] ?? 'No nearby mandis').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> priceTrend({
    required String commodity,
    String? state,
    String? district,
    int days = 7,
  }) async {
    try {
      final response = await _client.get(
        '/api/price-trend/$commodity',
        queryParameters: <String, dynamic>{
          'days': days,
          if (state != null && state.isNotEmpty) 'state': state,
          if (district != null && district.isNotEmpty) 'district': district,
        },
      );

      final body = asMap(parseBody(response));
      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }

      return ApiResult.failure(
        (body['error'] ?? 'Unable to load trend').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }
}
