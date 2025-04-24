library dev_console;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

// 导出所有公开的类和枚举
export 'src/log_manager.dart' show LogLevel;
export 'src/api_monitor.dart' show RequestStatus;
export 'src/api_logging/api_logger.dart' show ApiLogger, ApiLoggerFactory;
export 'src/event_tracker.dart' show EventStatus;

// 导入内部实现
import 'src/console_overlay.dart';
import 'src/log_manager.dart';
import 'src/api_monitor.dart';
import 'src/event_tracker.dart';
import 'src/api_logging/api_logger.dart';
import 'dart:async';

/// 全局访问点，可以直接使用 devConsole 访问开发控制台的功能
final DevConsole devConsole = DevConsole.instance;

/// 开发控制台主题配置
class DevConsoleTheme {
  /// 主色调
  final Color primaryColor;

  /// 背景色
  final Color backgroundColor;

  /// 文本颜色
  final Color textColor;

  /// 创建一个开发控制台主题
  DevConsoleTheme({
    this.primaryColor = Colors.greenAccent,
    this.backgroundColor = const Color(0xF01E1E1E),
    this.textColor = Colors.white,
  });
}

/// 开发控制台插件
///
/// 提供日志管理、接口监听和埋点调试功能
class DevConsole {
  /// 单例实例
  static final DevConsole instance = DevConsole._internal();

  /// 私有构造函数
  DevConsole._internal();

  /// 存储当前显示的控制台窗口
  static OverlayEntry? _currentConsoleEntry;

  /// 日志管理器实例
  late final LogManager logManager;

  /// API监听器实例
  late final ApiMonitor apiMonitor;

  /// 埋点事件追踪器实例
  late final EventTracker eventTracker;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 主题配置
  DevConsoleTheme? _theme;

  /// 是否在发布版本中启用
  bool _enableInRelease = false;

  /// 事件数据源函数，用于获取外部埋点事件数据
  List<Map<String, dynamic>> Function()? _eventDataSource;

  /// 事件流订阅
  StreamSubscription? _eventStreamSubscription;

  /// 最新的事件数据缓存
  List<Map<String, dynamic>> _latestEvents = [];

  /// 设置事件数据源
  ///
  /// [dataSource] 一个函数，返回埋点事件数据列表
  /// 设置后，开发控制台将从该数据源获取埋点事件，而不是使用内部事件追踪器
  void setEventDataSource(List<Map<String, dynamic>> Function() dataSource) {
    _eventDataSource = dataSource;
    // 立即获取一次最新数据
    _refreshLatestEvents();
  }

  /// 设置事件流
  ///
  /// [eventStream] 事件流，当事件队列变化时会发出通知
  /// 设置后，开发控制台将自动更新事件列表
  void setEventStream(Stream<List<Map<String, dynamic>>> eventStream) {
    // 取消旧的订阅
    _eventStreamSubscription?.cancel();

    // 订阅新的事件流
    _eventStreamSubscription = eventStream.listen((events) {
      _latestEvents = events;
      log('事件队列已更新，当前有 ${events.length} 个事件', tag: 'DevConsole');
    });
  }

  // 刷新最新事件数据
  void _refreshLatestEvents() {
    if (_eventDataSource != null) {
      try {
        _latestEvents = _eventDataSource!();
      } catch (e) {
        log('获取外部事件数据源失败: $e', level: LogLevel.error, tag: 'DevConsole');
      }
    }
  }

  /// 获取所有埋点事件
  List<Map<String, dynamic>> getEvents() {
    if (!_isInitialized) return [];

    // 如果有缓存的最新事件数据，直接返回
    if (_latestEvents.isNotEmpty) {
      return _latestEvents;
    }

    // 如果没有缓存，但有数据源，则尝试获取
    if (_eventDataSource != null) {
      _refreshLatestEvents();
      return _latestEvents;
    }

    // 使用内部事件追踪器的数据
    return eventTracker.getEvents();
  }

  /// 释放资源
  void dispose() {
    // 取消事件流订阅
    _eventStreamSubscription?.cancel();
    _eventStreamSubscription = null;
  }

  /// 初始化开发控制台
  ///
  /// [maxLogCount] 最大日志数量
  /// [maxRequestCount] 最大请求记录数量
  /// [maxEventCount] 最大埋点事件数量
  /// [theme] 主题配置
  /// [enableInRelease] 是否在发布版本中启用
  void initialize({
    int maxLogCount = 500,
    int maxRequestCount = 100,
    int maxEventCount = 100,
    DevConsoleTheme? theme,
    bool enableInRelease = false,
  }) {
    // 如果已经初始化，则直接返回
    if (_isInitialized) return;

    // 如果是发布版本且未启用，则直接返回
    if (kReleaseMode && !enableInRelease) return;

    // 保存配置
    _theme = theme;
    _enableInRelease = enableInRelease;

    // 初始化日志管理器
    logManager = LogManager(maxLogCount: maxLogCount);
    logManager.initialize();

    // 初始化API监听器
    apiMonitor = ApiMonitor(maxRequestCount: maxRequestCount);
    apiMonitor.initialize();

    // 初始化事件追踪器
    eventTracker = EventTracker(maxEventCount: maxEventCount);
    eventTracker.initialize();

    _isInitialized = true;

    // 记录初始化日志
    log('DevConsole 已初始化', level: LogLevel.info, tag: 'DevConsole');
  }

  /// 显示开发控制台
  ///
  /// 在当前上下文中显示开发控制台悬浮窗
  void show(BuildContext context) {
    // 如果未初始化，则先初始化
    if (!_isInitialized) {
      initialize();
    }

    // 如果是发布版本且未启用，则直接返回
    if (kReleaseMode && !_enableInRelease) return;

    // 显示控制台悬浮窗
    try {
      // 首先尝试获取最近的 Navigator
      final navigator = Navigator.of(context, rootNavigator: true);

      // 如果能获取到 Navigator，则使用 showDialog
      showDialog(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => ConsoleOverlay(
          theme: _theme,
          logManager: logManager,
          apiMonitor: apiMonitor,
          eventTracker: eventTracker,
        ),
      );
    } catch (e) {
      print('无法使用 Navigator 显示开发控制台: $e');

      // 如果无法使用 Navigator，尝试使用 Overlay
      try {
        // 获取 Overlay
        final overlay = Overlay.of(context);
        if (overlay != null) {
          // 声明 OverlayEntry 变量，但暂不初始化
          late final OverlayEntry entry;

          // 初始化 OverlayEntry
          entry = OverlayEntry(
            builder: (overlayContext) => Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  // 半透明背景
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        // 点击背景关闭
                        entry.remove();
                      },
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                  // 控制台内容
                  SafeArea(
                    child: Center(
                      child: Container(
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _theme?.backgroundColor ??
                              const Color(0xF01E1E1E),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 标题栏
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'DevConsole',
                                    style: TextStyle(
                                      color: _theme?.textColor ?? Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: _theme?.textColor ?? Colors.white,
                                    ),
                                    onPressed: () {
                                      // 关闭 Overlay
                                      entry.remove();
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                            ),
                            // 控制台内容
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: 800,
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.8,
                                ),
                                child: ConsoleOverlay(
                                  theme: _theme,
                                  logManager: logManager,
                                  apiMonitor: apiMonitor,
                                  eventTracker: eventTracker,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          // 插入 Overlay
          overlay.insert(entry);
          return;
        }
      } catch (overlayError) {
        print('无法使用 Overlay 显示开发控制台: $overlayError');
      }

      // 如果 Navigator 和 Overlay 都失败，尝试使用 SnackBar
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法显示开发控制台: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: '了解更多',
              onPressed: () {
                log('用户点击了解更多', level: LogLevel.info, tag: 'DevConsole');
                // 这里可以添加更多信息或操作
              },
            ),
          ),
        );
      } catch (snackBarError) {
        // 如果连 SnackBar 都无法显示，尝试使用 WidgetsBinding
        print('尝试使用 WidgetsBinding 显示开发控制台');

        // 使用 WidgetsBinding 在下一帧渲染时尝试显示一个简单的控制台
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            // 创建一个简单的控制台窗口
            final entry = OverlayEntry(
              builder: (context) => Material(
                type: MaterialType.transparency,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      width: 300,
                      height: 200,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _theme?.backgroundColor ?? const Color(0xF01E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'DevConsole',
                            style: TextStyle(
                              color: _theme?.textColor ?? Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '无法显示完整控制台',
                            style: TextStyle(
                              color: _theme?.textColor ?? Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _currentConsoleEntry?.remove();
                              _currentConsoleEntry = null;
                            },
                            child: Text('关闭'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _theme?.primaryColor ?? Colors.greenAccent,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );

            // 保存当前的 entry
            _currentConsoleEntry = entry;

            // 尝试找到一个可用的 OverlayState
            final rootContext = WidgetsBinding.instance.renderViewElement;
            if (rootContext != null) {
              final overlayState = Overlay.maybeOf(rootContext);
              if (overlayState != null) {
                overlayState.insert(entry);
                print('成功使用 WidgetsBinding 显示简单控制台');
                return;
              }
            }

            print('无法找到可用的 OverlayState，无法显示控制台');
          } catch (widgetsBindingError) {
            print('使用 WidgetsBinding 显示控制台失败: $widgetsBindingError');
          }
        });
      }

      // 尝试使用独立显示方法
      _showWithWidgetsBinding(context);
    }
  }

  /// 使用原始渲染视图显示控制台
  ///
  /// 这个方法使用最底层的 API，不依赖于任何 Flutter widget
  void _showWithRawRenderView() {
    print('尝试使用原始渲染视图显示控制台');

    // 如果已经有一个控制台在显示，先关闭它
    _currentConsoleEntry?.remove();
    _currentConsoleEntry = null;

    // 创建一个悬浮窗口
    final overlayKey = GlobalKey<OverlayState>();
    final overlayEntry = OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: 300,
              height: 200,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _theme?.backgroundColor ?? const Color(0xF01E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'DevConsole',
                    style: TextStyle(
                      color: _theme?.textColor ?? Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '无法显示完整控制台',
                    style: TextStyle(
                      color: _theme?.textColor ?? Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _currentConsoleEntry?.remove();
                      _currentConsoleEntry = null;
                    },
                    child: Text('关闭'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _theme?.primaryColor ?? Colors.greenAccent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // 保存当前的 entry
    _currentConsoleEntry = overlayEntry;

    // 尝试插入到 widget 树中
    try {
      final pipelineOwner = WidgetsBinding.instance.pipelineOwner;
      final renderViewElement = WidgetsBinding.instance.renderViewElement;
      if (renderViewElement != null) {
        final overlayState = Overlay.maybeOf(renderViewElement);
        if (overlayState != null) {
          overlayState.insert(overlayEntry);
          print('成功使用原始渲染视图显示简单控制台');
          return;
        }
      }
      print('无法找到可用的 OverlayState，无法显示控制台');
    } catch (e) {
      print('使用原始渲染视图显示控制台失败: $e');
    }
  }

  /// 使用 WidgetsBinding 显示控制台
  ///
  /// 这个方法不依赖于 Navigator 或 Overlay，可以在任何情况下使用
  void _showWithWidgetsBinding(BuildContext context) {
    // 如果已经有一个控制台在显示，先关闭它
    _currentConsoleEntry?.remove();
    _currentConsoleEntry = null;

    // 创建一个 OverlayEntry
    final entry = OverlayEntry(
      builder: (overlayContext) => _buildConsoleWidget(overlayContext),
    );

    // 保存当前的 entry
    _currentConsoleEntry = entry;

    // 使用 WidgetsBinding 在下一帧渲染时添加覆盖层
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // 尝试获取应用的根 BuildContext
        final rootContext = WidgetsBinding.instance.renderViewElement;
        if (rootContext != null) {
          // 尝试找到 OverlayState
          final overlayState = Overlay.maybeOf(rootContext);
          if (overlayState != null) {
            // 如果找到了 OverlayState，使用它
            overlayState.insert(entry);
            print('成功使用 WidgetsBinding 显示控制台');
            return;
          }
        }

        // 如果无法找到 OverlayState，使用更底层的方法
        print('无法找到 OverlayState，尝试使用更底层的方法');
        _showWithRawRenderView();
      } catch (e) {
        print('使用 WidgetsBinding 显示控制台失败: $e');
        _showWithRawRenderView();
      }
    });
  }

  /// 构建控制台 Widget
  Widget _buildConsoleWidget(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 半透明背景
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // 点击背景关闭
                _currentConsoleEntry?.remove();
                _currentConsoleEntry = null;
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          // 控制台内容
          SafeArea(
            child: Center(
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _theme?.backgroundColor ?? const Color(0xF01E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题栏
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DevConsole',
                            style: TextStyle(
                              color: _theme?.textColor ?? Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: _theme?.textColor ?? Colors.white,
                            ),
                            onPressed: () {
                              // 关闭控制台
                              _currentConsoleEntry?.remove();
                              _currentConsoleEntry = null;
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                    // 控制台内容
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 800,
                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                        ),
                        child: ConsoleOverlay(
                          theme: _theme,
                          logManager: logManager,
                          apiMonitor: apiMonitor,
                          eventTracker: eventTracker,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 关闭开发控制台
  void dismiss(BuildContext context) {
    // 如果有当前显示的控制台窗口，关闭它
    if (_currentConsoleEntry != null) {
      _currentConsoleEntry?.remove();
      _currentConsoleEntry = null;
      return;
    }

    // 否则尝试使用 Navigator 关闭
    try {
      Navigator.of(context).pop();
    } catch (e) {
      print('无法关闭开发控制台: $e');
    }
  }

  /// 添加日志
  ///
  /// [message] 日志消息
  /// [level] 日志级别
  /// [tag] 日志标签
  /// [stackTrace] 堆栈信息
  /// [error] 错误对象
  void log(String message,
      {LogLevel level = LogLevel.info,
      String? tag,
      StackTrace? stackTrace,
      Object? error}) {
    // 如果未初始化，则先初始化
    if (!_isInitialized) {
      initialize();
    }

    // 如果是发布版本且未启用，则直接返回
    if (kReleaseMode && !_enableInRelease) return;

    logManager.addLog(message,
        level: level, tag: tag ?? 'App', stackTrace: stackTrace, error: error);
  }

  /// 添加API请求记录
  ///
  /// [url] 请求URL
  /// [method] 请求方法
  /// [headers] 请求头
  /// [data] 请求数据
  /// [queryParameters] 查询参数
  /// [statusCode] 状态码
  /// [response] 响应数据
  /// [error] 错误信息
  /// [status] 请求状态
  /// [startTime] 请求开始时间
  void logApiRequest(
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
    // 如果未初始化，则先初始化
    if (!_isInitialized) {
      initialize();
    }

    // 如果是发布版本且未启用，则直接返回
    if (kReleaseMode && !_enableInRelease) return;

    apiMonitor.addRequest(
      url,
      method,
      headers: headers,
      data: data,
      queryParameters: queryParameters,
      statusCode: statusCode,
      response: response,
      error: error,
      status: status,
      startTime: startTime,
    );
  }

  /// 获取API日志记录器
  ///
  /// 返回一个可以用于记录API请求的ApiLogger实例
  ///
  ApiLogger getApiLogger() {
    // 如果未初始化，则先初始化
    if (!_isInitialized) {
      initialize();
    }

    // 如果是发布版本且未启用，则直接返回null
    if (kReleaseMode && !_enableInRelease) {
      // 创建一个临时的不记录任何内容的ApiLogger
      return ApiLoggerFactory.create(apiMonitor: apiMonitor);
    }

    return ApiLoggerFactory.create(apiMonitor: apiMonitor);
  }

  /// 清除所有日志
  void clearLogs() {
    if (!_isInitialized) return;
    logManager.clearLogs();
  }

  /// 清除所有API请求记录
  void clearApiRequests() {
    if (!_isInitialized) return;
    apiMonitor.clearRequests();
  }

  /// 获取所有日志
  List<Map<String, dynamic>> getLogs() {
    if (!_isInitialized) return [];
    return logManager.getLogs();
  }

  /// 获取所有API请求记录
  List<Map<String, dynamic>> getApiRequests() {
    if (!_isInitialized) return [];
    return apiMonitor.getRequests();
  }

  /// 添加埋点事件
  ///
  /// [eventName] 事件名称
  /// [parameters] 事件参数
  /// [category] 事件分类
  void trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    String? category,
  }) {
    // 如果未初始化，则先初始化
    if (!_isInitialized) {
      initialize();
    }

    // 如果是发布版本且未启用，则直接返回
    if (kReleaseMode && !_enableInRelease) return;

    eventTracker.trackEvent(
      eventName,
      parameters: parameters,
      category: category,
    );
  }

  /// 清除所有埋点事件
  void clearEvents() {
    if (!_isInitialized) return;
    eventTracker.clearEvents();
  }
}
