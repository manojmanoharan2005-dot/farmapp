import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        validateStatus: (int? code) => code != null && code < 500,
        responseType: ResponseType.plain,
      ),
    );

    if (kIsWeb) {
      // Browser handles cookies on web; this enables sending credentials.
      dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
      dio.options.extra['withCredentials'] = true;
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      final cookieJar = PersistCookieJar(
        storage: FileStorage('${appDocDir.path}/cookies/'),
        ignoreExpires: false,
      );
      dio.interceptors.add(CookieManager(cookieJar));
    }

    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: false),
    );

    _initialized = true;
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<dynamic>> postJson(
    String path,
    Map<String, dynamic> data, {
    Options? options,
  }) {
    final requestOptions = (options ?? Options()).copyWith(
      contentType: Headers.jsonContentType,
    );

    return dio.post<dynamic>(path, data: data, options: requestOptions);
  }

  Future<Response<dynamic>> postForm(
    String path,
    Map<String, dynamic> data, {
    bool followRedirects = true,
    bool useMultipart = false,
    Options? options,
  }) {
    final payload = useMultipart ? FormData.fromMap(data) : data;

    final requestOptions = (options ?? Options()).copyWith(
      contentType: useMultipart
          ? Headers.multipartFormDataContentType
          : Headers.formUrlEncodedContentType,
      followRedirects: followRedirects,
      validateStatus: (int? code) => code != null && code < 500,
    );

    return dio.post<dynamic>(path, data: payload, options: requestOptions);
  }

  Future<Response<dynamic>> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    required MultipartFile file,
    String fileField = 'image',
    Options? options,
  }) {
    final data = FormData.fromMap(<String, dynamic>{
      ...fields,
      fileField: file,
    });

    final requestOptions = (options ?? Options()).copyWith(
      contentType: Headers.multipartFormDataContentType,
    );

    return dio.post<dynamic>(path, data: data, options: requestOptions);
  }
}
