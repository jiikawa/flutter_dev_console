import 'dart:collection';

/// 请求状态
enum RequestStatus {
  /// 请求进行中
  pending,

  /// 请求成功
  success,

  /// 请求失败
  failed,
}

/// API请求监听器
///
/// 负责监听和记录应用中的API请求
///
/// 支持添加新请求和更新现有请求的状态，使得一个API请求的完整生命周期
/// 可以在单个记录中跟踪，而不是创建多个记录。
class ApiMonitor {
  /// 创建一个API监听器实例
  ///
  /// [maxRequestCount] 最大请求记录数量
  ApiMonitor({int maxRequestCount = 100}) : _maxRequestCount = maxRequestCount;

  /// 最大请求数量
  final int _maxRequestCount;

  /// 请求队列
  final Queue<Map<String, dynamic>> _requests = Queue<Map<String, dynamic>>();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化API监听器
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// 添加请求记录
  ///
  /// 创建一个新的API请求记录，并返回请求ID。
  /// 此ID可用于后续通过updateRequest方法更新请求状态，
  /// 从而实现在同一条记录中跟踪请求的完整生命周期。
  ///
  /// 返回请求ID，可用于后续更新请求状态
  String addRequest(
    String url,
    String method, {
    Map<String, dynamic>? headers,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    int? statusCode,
    dynamic response,
    String? error,
    RequestStatus status = RequestStatus.success,
    DateTime? startTime,
  }) {
    if (_requests.length >= _maxRequestCount) {
      _requests.removeFirst();
    }

    final now = DateTime.now();
    final requestStartTime = startTime ?? now;
    final duration = now.difference(requestStartTime).inMilliseconds;
    final requestId = now.millisecondsSinceEpoch.toString();

    final request = {
      'id': requestId,
      'url': url,
      'method': method,
      'headers': headers,
      'data': data,
      'queryParameters': queryParameters,
      'status': status,
      'startTime': requestStartTime,
      'response': response,
      'error': error,
      'statusCode': statusCode,
      'endTime': now,
      'duration': duration,
    };

    _requests.add(request);
    return requestId;
  }

  /// 更新请求状态
  ///
  /// 根据请求ID查找并更新现有请求的状态和相关信息。
  /// 这是实现"一个请求只显示一条记录"的核心方法，
  /// 它允许在请求完成时更新之前创建的请求记录，
  /// 而不是创建新的记录。
  ///
  /// [requestId] 请求ID，由addRequest方法返回
  /// [statusCode] 响应状态码
  /// [response] 响应数据
  /// [error] 错误信息
  /// [status] 请求状态（success或failed）
  ///
  /// 返回是否成功更新（true表示找到并更新了请求，false表示未找到请求）
  bool updateRequest(
    String requestId, {
    int? statusCode,
    dynamic response,
    String? error,
    RequestStatus? status,
  }) {
    final now = DateTime.now();

    for (final request in _requests) {
      if (request['id'] == requestId) {
        // 计算请求持续时间
        final startTime = request['startTime'] as DateTime;
        final duration = now.difference(startTime).inMilliseconds;

        // 更新请求信息
        if (status != null) request['status'] = status;
        if (response != null) request['response'] = response;
        if (error != null) request['error'] = error;
        if (statusCode != null) request['statusCode'] = statusCode;

        request['endTime'] = now;
        request['duration'] = duration;

        return true;
      }
    }

    return false; // 未找到请求
  }

  /// 获取所有请求
  List<Map<String, dynamic>> getRequests() {
    return _requests.toList().reversed.toList(); // 最新的请求在前面
  }

  /// 清除所有请求
  void clearRequests() {
    _requests.clear();
  }

  /// 生成测试请求
  void generateTestRequests() {
    addRequest(
      'https://api.example.com/users',
      'GET',
      headers: {'Authorization': 'Bearer token123'},
      response: {'id': 1, 'name': 'Test User'},
      statusCode: 200,
    );

    addRequest(
      'https://api.example.com/posts',
      'POST',
      data: {'title': 'New Post', 'content': 'Content'},
      response: {'id': 1, 'success': true},
      statusCode: 201,
    );

    addRequest(
      'https://api.example.com/invalid',
      'GET',
      error: '404 Not Found',
      statusCode: 404,
      status: RequestStatus.failed,
    );
  }
}
