import '../api_monitor.dart';

/// API 请求记录器
///
/// 提供手动记录 API 请求、响应和错误的方法
///
/// 优化设计：一个API请求只会显示一条记录，请求完成时会更新记录状态，
/// 而不是创建新的记录。这样可以更清晰地跟踪每个请求的完整生命周期。
class ApiLogger {
  /// API 监视器实例
  final ApiMonitor _apiMonitor;

  /// 存储请求ID的映射表，用于更新请求状态
  final Map<String, String> _requestIds = {};

  /// 创建一个 API 请求记录器
  ///
  /// [apiMonitor] 用于记录 API 请求的监视器
  ApiLogger({required ApiMonitor apiMonitor}) : _apiMonitor = apiMonitor;

  /// 生成请求的唯一键
  String _generateRequestKey(String url, String method) {
    return '$method:$url:${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 记录 API 请求（发送前）
  ///
  /// 创建一个新的API请求记录，状态为pending。
  /// 返回一个唯一键，可用于后续通过logResponse或logError更新此请求的状态。
  ///
  /// [url] 请求 URL
  /// [method] 请求方法（GET, POST 等）
  /// [headers] 请求头
  /// [data] 请求数据
  /// [queryParameters] 查询参数
  ///
  /// 返回请求的唯一键，可用于后续更新请求状态
  String logRequest(
    String url,
    String method, {
    Map<String, dynamic>? headers,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    final requestKey = _generateRequestKey(url, method);
    final requestId = _apiMonitor.addRequest(
      url,
      method,
      headers: headers,
      data: data,
      queryParameters: queryParameters,
      status: RequestStatus.pending,
    );

    // 存储请求ID，用于后续更新
    _requestIds[requestKey] = requestId;

    return requestKey;
  }

  /// 记录 API 响应（请求成功）
  ///
  /// 当API请求成功完成时调用此方法。它会尝试查找并更新之前通过logRequest创建的请求记录，
  /// 将其状态更新为success，并添加响应数据。如果找不到匹配的请求记录，则创建一个新记录。
  ///
  /// 支持两种调用方式：
  /// 1. 新版API：提供requestKey参数，更新现有请求
  /// 2. 旧版API：提供url和method参数，创建新请求或更新匹配的请求
  ///
  /// [url] 请求 URL（旧版API）
  /// [method] 请求方法（旧版API）
  /// [statusCode] 响应状态码
  /// [response] 响应数据
  /// [headers] 请求头（可选，旧版API）
  /// [data] 请求数据（可选，旧版API）
  /// [queryParameters] 查询参数（可选，旧版API）
  /// [requestKey] 请求唯一键，由logRequest返回（新版API）
  void logResponse(
    String urlOrRequestKey,
    String methodOrStatusCode,
    dynamic statusCodeOrResponse, [
    dynamic response,
    Map<String, dynamic>? headers,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  ]) {
    // 检查是否使用新版API（第二个参数是状态码）
    if (methodOrStatusCode.isEmpty ||
        int.tryParse(methodOrStatusCode) != null) {
      // 新版API调用方式
      final requestKey = urlOrRequestKey;
      final statusCode = int.tryParse(methodOrStatusCode) ?? 0;
      final responseData = statusCodeOrResponse;

      final requestId = _requestIds[requestKey];
      if (requestId != null) {
        // 更新现有请求
        _apiMonitor.updateRequest(
          requestId,
          statusCode: statusCode,
          response: responseData,
          status: RequestStatus.success,
        );

        // 请求完成后移除ID
        _requestIds.remove(requestKey);
      }
    } else {
      // 旧版API调用方式
      final url = urlOrRequestKey;
      final method = methodOrStatusCode;
      final statusCode = statusCodeOrResponse as int?;

      // 尝试查找匹配的请求ID
      String? matchedRequestKey;
      for (final entry in _requestIds.entries) {
        if (entry.key.contains('$method:$url:')) {
          matchedRequestKey = entry.key;
          break;
        }
      }

      if (matchedRequestKey != null) {
        // 找到匹配的请求，更新它
        final requestId = _requestIds[matchedRequestKey]!;
        _apiMonitor.updateRequest(
          requestId,
          statusCode: statusCode,
          response: response,
          status: RequestStatus.success,
        );

        // 请求完成后移除ID
        _requestIds.remove(matchedRequestKey);
      } else {
        // 未找到匹配的请求，创建新请求
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
    }
  }

  /// 记录 API 错误（请求失败）
  ///
  /// 当API请求失败时调用此方法。它会尝试查找并更新之前通过logRequest创建的请求记录，
  /// 将其状态更新为failed，并添加错误信息。如果找不到匹配的请求记录，则创建一个新记录。
  ///
  /// 支持两种调用方式：
  /// 1. 新版API：提供requestKey参数，更新现有请求
  /// 2. 旧版API：提供url和method参数，创建新请求或更新匹配的请求
  ///
  /// [url] 请求 URL（旧版API）
  /// [method] 请求方法（旧版API）
  /// [error] 错误信息
  /// [statusCode] 响应状态码（可选，旧版API）
  /// [headers] 请求头（可选，旧版API）
  /// [data] 请求数据（可选，旧版API）
  /// [queryParameters] 查询参数（可选，旧版API）
  /// [requestKey] 请求唯一键，由logRequest返回（新版API）
  void logError(
    String urlOrRequestKey,
    String methodOrError, [
    String? errorOrNull,
    int? statusCode,
    Map<String, dynamic>? headers,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  ]) {
    // 检查是否使用新版API（第三个参数为null）
    if (errorOrNull == null) {
      // 新版API调用方式
      final requestKey = urlOrRequestKey;
      final error = methodOrError;

      final requestId = _requestIds[requestKey];
      if (requestId != null) {
        // 更新现有请求
        _apiMonitor.updateRequest(
          requestId,
          statusCode: statusCode,
          error: error,
          status: RequestStatus.failed,
        );

        // 请求完成后移除ID
        _requestIds.remove(requestKey);
      }
    } else {
      // 旧版API调用方式
      final url = urlOrRequestKey;
      final method = methodOrError;
      final error = errorOrNull;

      // 尝试查找匹配的请求ID
      String? matchedRequestKey;
      for (final entry in _requestIds.entries) {
        if (entry.key.contains('$method:$url:')) {
          matchedRequestKey = entry.key;
          break;
        }
      }

      if (matchedRequestKey != null) {
        // 找到匹配的请求，更新它
        final requestId = _requestIds[matchedRequestKey]!;
        _apiMonitor.updateRequest(
          requestId,
          statusCode: statusCode,
          error: error,
          status: RequestStatus.failed,
        );

        // 请求完成后移除ID
        _requestIds.remove(matchedRequestKey);
      } else {
        // 未找到匹配的请求，创建新请求
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
