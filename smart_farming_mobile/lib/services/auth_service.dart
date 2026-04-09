import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/network/api_result.dart';
import 'base_service.dart';

class PincodeLookupData {
  const PincodeLookupData({
    required this.state,
    required this.district,
    required this.villages,
    required this.message,
  });

  final String state;
  final String district;
  final List<String> villages;
  final String message;
}

class AuthService extends BaseService {
  final ApiClient _client = ApiClient.instance;

  String _friendlyNetworkMessage(
    DioException error, {
    String fallback = 'Unable to fetch pincode details. Please select state and district manually.',
  }) {
    final response = error.response;
    if (response != null) {
      final body = asMap(parseBody(response));
      final message = body['message'] ?? body['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Pincode lookup timed out. Please select state and district manually.';
    }

    return fallback;
  }

  Map<String, List<String>> _parseStatesDistricts(dynamic raw) {
    final rawMap = asMap(raw);
    final result = <String, List<String>>{};

    for (final entry in rawMap.entries) {
      final state = entry.key.toString().trim();
      if (state.isEmpty) continue;

      final districts = <String>[];
      if (entry.value is List) {
        for (final district in (entry.value as List)) {
          final name = district.toString().trim();
          if (name.isNotEmpty) {
            districts.add(name);
          }
        }
      }

      districts.sort();
      result[state] = districts.toSet().toList(growable: false);
    }

    return result;
  }

  Future<ApiResult<Map<String, List<String>>>> fetchRegisterLocationConfig() async {
    try {
      final response = await _client.get('/api/register/location-config');
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        final parsed = _parseStatesDistricts(body['states_districts']);
        if (parsed.isNotEmpty) {
          return ApiResult.success(parsed);
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Failed to load state and district data').toString(),
      );
    } catch (error) {
      return failureFromError<Map<String, List<String>>>(error);
    }
  }

  Future<ApiResult<PincodeLookupData>> lookupPincode(String pincode) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      return ApiResult.failure('Please enter a valid 6-digit pincode');
    }

    Future<ApiResult<PincodeLookupData>> parsePostalPayload(
      dynamic rawPayload,
    ) async {
      dynamic payloadSource = rawPayload;
      if (payloadSource is String) {
        try {
          payloadSource = jsonDecode(payloadSource);
        } catch (_) {
          payloadSource = <dynamic>[];
        }
      }

      final payload = payloadSource is List ? payloadSource : <dynamic>[];
      if (payload.isEmpty || payload.first is! Map) {
        return ApiResult.failure('Invalid pincode response');
      }

      final first = Map<String, dynamic>.from(payload.first as Map);
      if ((first['Status'] ?? '').toString().toLowerCase() != 'success') {
        final message = (first['Message'] ?? 'Invalid pincode').toString();
        return ApiResult.failure(message);
      }

      final postOffices = first['PostOffice'] is List
          ? first['PostOffice'] as List
          : <dynamic>[];
      if (postOffices.isEmpty || postOffices.first is! Map) {
        return ApiResult.failure('No location details found for this pincode');
      }

      final firstOffice = Map<String, dynamic>.from(postOffices.first as Map);
      final state = (firstOffice['State'] ?? '').toString().trim();
      final district = (firstOffice['District'] ?? '').toString().trim();

      if (state.isEmpty || district.isEmpty) {
        return ApiResult.failure('Incomplete location details for this pincode');
      }

      final villages = <String>[];
      for (final office in postOffices) {
        if (office is! Map) continue;
        final name = (office['Name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          villages.add(name);
        }
      }

      villages.sort();

      return ApiResult.success(
        PincodeLookupData(
          state: state,
          district: district,
          villages: villages.toSet().toList(growable: false),
          message: 'Location found: $district, $state',
        ),
      );
    }

    Future<ApiResult<PincodeLookupData>> directLookup() async {
      try {
        final response = await _client.get(
          'https://api.postalpincode.in/pincode/$pincode',
          options: Options(responseType: ResponseType.json),
        );

        return parsePostalPayload(response.data);
      } on DioException catch (_) {
        return ApiResult.failure(
          'Pincode service is temporarily unavailable. Please select state and district manually.',
        );
      } catch (_) {
        return ApiResult.failure(
          'Pincode service is temporarily unavailable. Please select state and district manually.',
        );
      }
    }

    try {
      final response = await _client.get('/api/register/pincode/$pincode');
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        final villages = <String>[];
        final rawVillages = body['villages'];
        if (rawVillages is List) {
          for (final village in rawVillages) {
            final value = village.toString().trim();
            if (value.isNotEmpty) {
              villages.add(value);
            }
          }
        }

        return ApiResult.success(
          PincodeLookupData(
            state: (body['state'] ?? '').toString(),
            district: (body['district'] ?? '').toString(),
            villages: villages.toSet().toList(growable: false),
            message: (body['message'] ?? 'Location found').toString(),
          ),
          statusCode: response.statusCode,
        );
      }

      final backendMessage =
          (body['message'] ?? 'Invalid pincode').toString();

      final fallback = await directLookup();
      if (fallback.isSuccess) {
        return fallback;
      }

      return ApiResult.failure(
        backendMessage,
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      // If backend lookup fails in production (e.g., outbound restrictions),
      // fallback to direct postal API lookup from the client.
      final fallback = await directLookup();
      if (fallback.isSuccess) {
        return fallback;
      }

      return ApiResult.failure(
        _friendlyNetworkMessage(error),
        statusCode: error.response?.statusCode,
      );
    } catch (_) {
      final fallback = await directLookup();
      if (fallback.isSuccess) {
        return fallback;
      }

      return ApiResult.failure(
        'Unable to fetch pincode details. Please select state and district manually.',
      );
    }
  }

  Future<bool> _hasActiveSession() async {
    final sessionCheck = await validateSession();
    return sessionCheck.data == true;
  }

  Future<ApiResult<void>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.postForm(
        '/login',
        <String, dynamic>{'email': email, 'password': password},
        followRedirects: false,
        options: Options(validateStatus: (int? c) => c != null && c < 400),
      );

      final location = response.headers.map['location']?.join(',') ?? '';
      if (response.statusCode == 302 || location.contains('/dashboard')) {
        return ApiResult.success(null, statusCode: response.statusCode);
      }

      // On web, the browser can auto-follow redirects and return 200 HTML.
      // Validate session to detect successful login in that case.
      if (await _hasActiveSession()) {
        return ApiResult.success(null, statusCode: response.statusCode);
      }

      final bodyText = response.data?.toString() ?? '';
      if (bodyText.contains('Invalid email or password')) {
        return ApiResult.failure('Invalid email or password');
      }

      return ApiResult.failure('Invalid email or password');
    } catch (error) {
      return failureFromError<void>(error);
    }
  }

  Future<ApiResult<void>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String state,
    required String district,
    String village = '',
    String pincode = '',
  }) async {
    try {
      final response = await _client.postForm(
        '/register',
        <String, dynamic>{
          'name': name,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'phone': phone,
          'state': state,
          'district': district,
          'village': village,
          'pincode': pincode,
        },
        followRedirects: false,
        options: Options(validateStatus: (int? c) => c != null && c < 400),
      );

      final location = response.headers.map['location']?.join(',') ?? '';
      if (response.statusCode == 302 || location.contains('/dashboard')) {
        return ApiResult.success(null, statusCode: response.statusCode);
      }

      // Same fallback as login for web redirect handling.
      if (await _hasActiveSession()) {
        return ApiResult.success(null, statusCode: response.statusCode);
      }

      return ApiResult.failure(
        'Registration failed. Please verify OTP and retry.',
      );
    } catch (error) {
      return failureFromError<void>(error);
    }
  }

  Future<ApiResult<String>> sendRegistrationOtp(String email) async {
    try {
      final response = await _client.postJson(
        '/api/register/send-otp',
        <String, dynamic>{'email': email},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success((body['message'] ?? 'OTP sent').toString());
      }

      return ApiResult.failure(
        (body['message'] ?? body['error'] ?? 'Failed to send OTP').toString(),
      );
    } catch (error) {
      return failureFromError<String>(error);
    }
  }

  Future<ApiResult<String>> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.postJson(
        '/api/register/verify-otp',
        <String, dynamic>{'email': email, 'otp': otp},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success((body['message'] ?? 'Verified').toString());
      }

      return ApiResult.failure(
        (body['message'] ?? body['error'] ?? 'OTP verification failed')
            .toString(),
      );
    } catch (error) {
      return failureFromError<String>(error);
    }
  }

  Future<ApiResult<String>> requestForgotPasswordOtp(String identifier) async {
    try {
      final response = await _client.postJson(
        '/api/forgot-password/request-otp',
        <String, dynamic>{'identifier': identifier},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success((body['message'] ?? 'OTP sent').toString());
      }

      return ApiResult.failure(
        (body['message'] ?? body['error'] ?? 'Failed to send OTP').toString(),
      );
    } catch (error) {
      return failureFromError<String>(error);
    }
  }

  Future<ApiResult<String>> verifyForgotPasswordOtp(String otp) async {
    try {
      final response = await _client.postJson(
        '/api/forgot-password/verify-otp',
        <String, dynamic>{'otp': otp},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(
          (body['message'] ?? 'OTP verified').toString(),
        );
      }

      return ApiResult.failure(
        (body['message'] ?? body['error'] ?? 'OTP verification failed')
            .toString(),
      );
    } catch (error) {
      return failureFromError<String>(error);
    }
  }

  Future<ApiResult<String>> resetPassword(String password) async {
    try {
      final response = await _client.postJson(
        '/api/forgot-password/reset-password',
        <String, dynamic>{'password': password},
      );
      final body = asMap(parseBody(response));

      if ((body['success'] ?? false) == true) {
        return ApiResult.success(
          (body['message'] ?? 'Password reset successful').toString(),
        );
      }

      return ApiResult.failure(
        (body['message'] ?? body['error'] ?? 'Failed to reset password')
            .toString(),
      );
    } catch (error) {
      return failureFromError<String>(error);
    }
  }

  Future<ApiResult<void>> logout() async {
    try {
      await _client.get('/logout');
      return ApiResult.success(null);
    } catch (error) {
      return failureFromError<void>(error);
    }
  }

  Future<ApiResult<bool>> validateSession() async {
    try {
      final response = await _client.get('/api/weather-update');
      final body = parseBody(response);

      if (response.statusCode == 200 && body is Map) {
        return ApiResult.success(true);
      }

      return ApiResult.success(false);
    } catch (_) {
      return ApiResult.success(false);
    }
  }
}
