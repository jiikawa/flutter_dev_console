import '../api_monitor.dart';

/// API 请求记录器
///
/// 提供手动记录 API 请求、响应和错误的方法
class ApiLogger {
  /// API 监视器实例
  final ApiMonitor _apiMonitor;

  /// 创建一个 API 请求记录器
  ///
  /// [apiMonitor] 用于记录 API 请求的监视器
  ApiLogger({required ApiMonitor apiMonitor}) : _apiMonitor = apiMonitor;

  /// 记录 API 请求（发送前）
  ///
  /// [url] 请求 URL
  /// [method] 请求方法（GET, POST 等）
  /// [headers] 请求头
  /// [data] 请求数据
  /// [queryParameters] 查询参数
  void logRequest(
    String url,
    String method, {
    Map<String, dynamic>? headers,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    _apiMonitor.addRequest(
      url,
      method,
      headers: headers,
      data: data,
      queryParameters: queryParameters,
      status: RequestStatus.pending,
    );
  }

  /// 记录 API 响应（请求成功）
  ///
  /// [url] 请求 URL
  /// [method] 请求方法
  /// [statusCode] 响应状态码
  /// [response] 响应数据
  /// [headers] 请求头（可选）
  /// [data] 请求数据（可选）
  /// [queryParameters] 查询参数（可选）
  void logResponse(
    String url,
    String method,
    int? statusCode,
    dynamic response, {
    Map<String, dynamic>? headers,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    _apiMonitor.addRequest(
      url,
      method,
      headers: headers,
      data: data,
      queryParameters: queryParameters,
      statusCode: statusCode,
      response: response,
      status: RequestStatus.success,
    );
  }

  /// 记录 API 错误（请求失败）
  ///
  /// [url] 请求 URL
  /// [method] 请求方法
  /// [error] 错误信息
  /// [statusCode] 响应状态码（可选）
  /// [headers] 请求头（可选）
  /// [data] 请求数据（可选）
  /// [queryParameters] 查询参数（可选）
  void logError(
    String url,
    String method,
    String error, {
    int? statusCode,
    Map<String, dynamic>? headers,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    _apiMonitor.addRequest(
      url,
      method,
      headers: headers,
      data: data,
      queryParameters: queryParameters,
      statusCode: statusCode,
      error: error,
      status: RequestStatus.failed,
    );
  }
}

/// API 日志工具
///
/// 提供创建 ApiLogger 实例的静态方法
class ApiLoggerFactory {
  /// 创建一个 API 请求记录器
  ///
  /// [apiMonitor] API 监视器实例
  static ApiLogger create({required ApiMonitor apiMonitor}) {
    return ApiLogger(apiMonitor: apiMonitor);
  }
}
