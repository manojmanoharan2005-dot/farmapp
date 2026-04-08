class ApiResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final int? statusCode;

  const ApiResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResult.success(T data, {int? statusCode}) {
    return ApiResult._(isSuccess: true, data: data, statusCode: statusCode);
  }

  factory ApiResult.failure(String error, {int? statusCode}) {
    return ApiResult._(isSuccess: false, error: error, statusCode: statusCode);
  }
}
