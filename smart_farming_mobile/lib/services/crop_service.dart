import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import 'base_service.dart';

class CropService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResult<Map<String, dynamic>>> predictCrop({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double ph,
    required double rainfall,
  }) async {
    try {
      final response = await _client
          .postJson('/api/crop/predict', <String, dynamic>{
            'nitrogen': nitrogen,
            'phosphorus': phosphorus,
            'potassium': potassium,
            'temperature': temperature,
            'humidity': humidity,
            'ph': ph,
            'rainfall': rainfall,
          });

      final body = asMap(parseBody(response));
      if ((body['success'] ?? false) == true) {
        return ApiResult.success(body);
      }

      return ApiResult.failure(
        (body['error'] ?? 'Crop prediction failed').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }

  Future<ApiResult<void>> saveGrowingPlan({
    required String cropName,
    required String startDate,
    required String harvestDate,
    String notes = '',
  }) async {
    try {
      final response = await _client
          .postForm('/growing/save', <String, dynamic>{
            'crop_name': cropName,
            'start_date': startDate,
            'harvest_date': harvestDate,
            'notes': notes,
          }, followRedirects: false);

      if ((response.statusCode ?? 500) < 400) {
        return ApiResult.success(null);
      }

      return ApiResult.failure('Failed to save growing activity');
    } catch (error) {
      return failureFromError<void>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> detectDisease({
    required String imagePath,
  }) async {
    try {
      final file = await MultipartFile.fromFile(imagePath);
      final response = await _client.postMultipart(
        '/disease-detection',
        fields: <String, dynamic>{},
        file: file,
      );

      final body = parseBody(response);

      if (body is Map<String, dynamic>) {
        return ApiResult.success(body);
      }

      return ApiResult.success(<String, dynamic>{
        'success': true,
        'result':
            'Image submitted. The backend returned an HTML response for this feature.',
      });
    } catch (error) {
      return failureFromError<Map<String, dynamic>>(error);
    }
  }
}
