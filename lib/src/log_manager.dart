import 'dart:collection';
import 'dart:async';

/// 日志级别
enum LogLevel {
  /// 调试级别，用于开发过程中的调试信息
  debug,

  /// 信息级别，用于记录一般信息
  info,

  /// 警告级别，用于记录可能的问题
  warning,

  /// 错误级别，用于记录错误和异常
  error,
}

/// 日志管理器
///
/// 负责收集、存储和管理应用日志
class LogManager {
  /// 创建一个日志管理器实例
  ///
  /// [maxLogCount] 最大日志数量
  LogManager({int maxLogCount = 1000}) : _maxLogCount = maxLogCount;

  /// 刷新定时器
  Timer? _refreshTimer;

  /// 最大日志数量
  final int _maxLogCount;

  /// 日志队列
  final Queue<Map<String, dynamic>> _logs = Queue<Map<String, dynamic>>();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化日志管理器
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// 添加日志
  ///
  /// [message] 日志消息
  /// [level] 日志级别
  /// [tag] 日志标签
  /// [stackTrace] 堆栈信息
  /// [error] 错误对象
  void addLog(String message,
      {LogLevel level = LogLevel.info,
      String? tag,
      StackTrace? stackTrace,
      Object? error}) {
    if (_logs.length >= _maxLogCount) {
      _logs.removeFirst();
    }

    _logs.add({
      'message': message,
      'level': level,
      'tag': tag ?? 'App',
      'time': DateTime.now(),
      'stackTrace': stackTrace != null ? stackTrace.toString() : null,
      'error': error != null ? error.toString() : null,
    });
  }

  /// 获取所有日志
  List<Map<String, dynamic>> getLogs() {
    return _logs.toList();
  }

  /// 清除所有日志
  void clearLogs() {
    _logs.clear();
  }

  /// 生成测试日志
  void generateTestLogs() {
    // 直接添加测试日志到队列
    addLog('这是一条调试日志 - ${DateTime.now()}', level: LogLevel.debug, tag: 'Debug');
    addLog('这是一条信息日志 - ${DateTime.now()}', level: LogLevel.info, tag: 'Info');
    addLog('这是一条警告日志 - ${DateTime.now()}',
        level: LogLevel.warning, tag: 'Warning');

    // 添加带有堆栈信息的错误日志
    try {
      throw Exception('这是一个测试异常');
    } catch (e, stack) {
      addLog('发生异常: $e',
          level: LogLevel.error, tag: 'Error', stackTrace: stack, error: e);
    }

    // 添加带有堆栈信息的网络错误
    try {
      throw Exception('HTTP请求失败');
    } catch (e, stack) {
      addLog('网络请求失败: 404 Not Found',
          level: LogLevel.error, tag: 'Network', stackTrace: stack, error: e);
    }

    // 添加带有堆栈信息的权限错误
    try {
      throw Exception('权限请求被拒绝');
    } catch (e, stack) {
      addLog('权限被拒绝: 相机',
          level: LogLevel.warning,
          tag: 'Permission',
          stackTrace: stack,
          error: e);
    }
  }
}
