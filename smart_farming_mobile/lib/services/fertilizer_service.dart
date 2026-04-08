import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import 'base_service.dart';

class FertilizerService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  List<Map<String, dynamic>> recommendLocally({
    required String crop,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double moisture,
  }) {
    final nDeficit = (100 - nitrogen).clamp(0, 100);
    final pDeficit = (60 - phosphorus).clamp(0, 60);
    final kDeficit = (50 - potassium).clamp(0, 50);

    final scores = <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'Urea (46-0-0)',
        'dosage': '50-100 kg/acre',
        'usage': 'Split doses during vegetative stage',
        'note': 'Boosts nitrogen level quickly',
        'score': nDeficit,
      },
      <String, dynamic>{
        'name': 'DAP (18-46-0)',
        'dosage': '75-125 kg/acre',
        'usage': 'Apply during sowing or transplant',
        'note': 'Best for root and early growth',
        'score': pDeficit,
      },
      <String, dynamic>{
        'name': 'MOP (0-0-60)',
        'dosage': '50-75 kg/acre',
        'usage': 'Apply during flowering and fruiting',
        'note': 'Improves fruit quality and stress tolerance',
        'score': kDeficit,
      },
      <String, dynamic>{
        'name': 'NPK 19-19-19',
        'dosage': '100-150 kg/acre',
        'usage': 'Basal dose for balanced feeding',
        'note': 'Balanced nutrient source for most crops',
        'score': (nDeficit + pDeficit + kDeficit) / 3,
      },
      <String, dynamic>{
        'name': 'Organic Compost',
        'dosage': '2-3 tons/acre',
        'usage': 'Before sowing and after every harvest cycle',
        'note': moisture < 40
            ? 'Useful for moisture retention in dry soil'
            : 'Improves soil microbial activity',
        'score': moisture < 40 ? 65.0 : 45.0,
      },
    ];

    scores.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

    return scores.take(4).map((item) {
      final score = (item['score'] as num).toDouble();
      final confidence = (40 + score).clamp(35, 95).round();
      return <String, dynamic>{
        ...item,
        'crop_type': crop,
        'confidence': confidence,
        'priority': confidence >= 70
            ? 'High'
            : confidence >= 50
            ? 'Medium'
            : 'Low',
      };
    }).toList();
  }

  Future<ApiResult<void>> saveRecommendation(
    Map<String, dynamic> recommendation,
  ) async {
    try {
      final response = await _client
          .postForm('/fertilizer/save', <String, dynamic>{
            'fertilizer_name': recommendation['name'],
            'crop_type': recommendation['crop_type'] ?? '',
            'priority': recommendation['priority'] ?? 'Medium',
            'dosage': recommendation['dosage'] ?? '',
            'usage': recommendation['usage'] ?? '',
            'note': recommendation['note'] ?? '',
            'confidence': recommendation['confidence']?.toString() ?? '0',
            'soil_type': recommendation['soil_type'] ?? '',
            'nitrogen': recommendation['nitrogen']?.toString() ?? '',
            'phosphorus': recommendation['phosphorus']?.toString() ?? '',
            'potassium': recommendation['potassium']?.toString() ?? '',
          }, followRedirects: false);

      if ((response.statusCode ?? 500) < 400) {
        return ApiResult.success(null);
      }
      return ApiResult.failure('Failed to save fertilizer recommendation');
    } catch (error) {
      return failureFromError<void>(error);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> deleteRecommendation(
    String id,
  ) async {
    try {
      final response = await _client.postForm(
        '/fertilizer/delete/$id',
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
}
