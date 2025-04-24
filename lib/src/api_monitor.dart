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
  void addRequest(
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

    final request = {
      'id': now.millisecondsSinceEpoch.toString(),
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
