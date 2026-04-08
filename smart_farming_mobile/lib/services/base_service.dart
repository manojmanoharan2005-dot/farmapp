import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/network/api_result.dart';

abstract class BaseService {
  dynamic parseBody(Response<dynamic> response) {
    final raw = response.data;

    if (raw is String) {
      final value = raw.trim();
      if (value.startsWith('{') || value.startsWith('[')) {
        try {
          return jsonDecode(value);
        } catch (_) {
          return raw;
        }
      }
      return raw;
    }

    return raw;
  }

  Map<String, dynamic> asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> asListOfMap(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((Map e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  ApiResult<T> failureFromError<T>(Object error) {
    if (error is DioException) {
      return ApiResult.failure(
        error.message ?? 'Network error',
        statusCode: error.response?.statusCode,
      );
    }

    return ApiResult.failure(error.toString());
  }
}
