import 'dart:collection';

/// 事件上传状态
enum EventStatus {
  /// 事件待上传
  pending,

  /// 事件上传成功
  success,

  /// 事件上传失败
  failed,
}

/// 埋点事件追踪器
///
/// 负责收集、存储和管理应用埋点事件
class EventTracker {
  /// 创建一个埋点事件追踪器实例
  ///
  /// [maxEventCount] 最大事件记录数量
  EventTracker({int maxEventCount = 100}) : _maxEventCount = maxEventCount;

  /// 最大事件数量
  final int _maxEventCount;

  /// 事件队列
  final Queue<Map<String, dynamic>> _events = Queue<Map<String, dynamic>>();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化事件追踪器
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// 添加事件记录
  ///
  /// [eventName] 事件名称
  /// [parameters] 事件参数
  /// [category] 事件分类
  /// [status] 事件上传状态
  void trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    String? category,
    EventStatus status = EventStatus.pending,
  }) {
    if (_events.length >= _maxEventCount) {
      _events.removeFirst();
    }

    final now = DateTime.now();
    final event = {
      'id': now.millisecondsSinceEpoch.toString(),
      'name': eventName,
      'parameters': parameters,
      'category': category ?? '默认',
      'time': now,
      'status': status,
      'errorMessage': null,
    };

    _events.add(event);
  }

  /// 更新埋点事件状态
  ///
  /// [eventId] 事件ID
  /// [status] 新的事件状态
  /// [errorMessage] 错误信息，仅在状态为failed时有效
  void updateEventStatus(
    String eventId,
    EventStatus status, {
    String? errorMessage,
  }) {
    for (var i = _events.length - 1; i >= 0; i--) {
      final event = _events.elementAt(i);
      if (event['id'] == eventId) {
        event['status'] = status;
        if (status == EventStatus.failed && errorMessage != null) {
          event['errorMessage'] = errorMessage;
        }
        break;
      }
    }
  }

  /// 获取所有事件
  List<Map<String, dynamic>> getEvents() {
    return _events.toList().reversed.toList(); // 最新的事件在前面
  }

  /// 清除所有事件
  void clearEvents() {
    _events.clear();
  }

  /// 生成测试事件
  void generateTestEvents() {
    trackEvent(
      'button_click',
      parameters: {'button_id': 'login_button', 'screen': 'login'},
      category: '用户交互',
    );

    trackEvent(
      'page_view',
      parameters: {'page': 'home', 'source': 'deeplink'},
      category: '页面浏览',
    );

    trackEvent(
      'purchase',
      parameters: {
        'product_id': 'pro_12345',
        'price': 99.99,
        'currency': 'CNY',
      },
      category: '交易',
    );

    trackEvent(
      'login',
      parameters: {'method': 'email', 'status': 'success'},
      category: '用户',
    );

    trackEvent(
      'search',
      parameters: {'keyword': 'Flutter教程', 'results': 15},
      category: '搜索',
    );
  }
}
