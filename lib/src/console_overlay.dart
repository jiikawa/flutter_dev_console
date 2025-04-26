import 'package:flutter/material.dart';
import 'log_manager.dart';
import 'api_monitor.dart';
import 'event_tracker.dart'; // Add this line
import '../dev_console.dart';

/// 开发控制台悬浮窗
///
/// 显示日志、API请求和埋点事件的悬浮窗口
class ConsoleOverlay extends StatefulWidget {
  /// 主题配置
  final DevConsoleTheme? theme;

  /// 日志管理器
  final LogManager logManager;

  /// API监听器
  final ApiMonitor apiMonitor;

  /// 埋点事件追踪器
  final EventTracker eventTracker;

  /// 创建一个开发控制台悬浮窗
  ///
  /// [theme] 主题配置
  /// [logManager] 日志管理器
  /// [apiMonitor] API监听器
  const ConsoleOverlay({
    super.key,
    this.theme,
    required this.logManager,
    required this.apiMonitor,
    required this.eventTracker, // Add this line
  });

  @override
  ConsoleOverlayState createState() => ConsoleOverlayState();
}

class ConsoleOverlayState extends State<ConsoleOverlay>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  int _selectedTabIndex = 0;
  Map<String, dynamic>? _currentDetailEvent;
  bool _showingDetails = false;
  Map<String, dynamic>? _currentApiRequest;
  bool _showingApiDetails = false;
  Map<String, dynamic>? _currentLog;
  bool _showingLogDetails = false;

  // 获取主题颜色
  Color get _primaryColor => widget.theme?.primaryColor ?? Colors.greenAccent;
  Color get _backgroundColor =>
      widget.theme?.backgroundColor ?? Color(0xF01E1E1E);
  Color get _textColor => widget.theme?.textColor ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
        style: TextStyle(decoration: TextDecoration.none), // 移除默认下划线
        child: Container(
            color: _backgroundColor,
            child: SafeArea(
              bottom: true,
              child: Column(
                children: [
                  _buildHeader(), // 标题
                  _buildTabBar(), // 标签栏
                  Expanded(
                    child: _buildTabContent(), // 内容区域
                  ),
                ],
              ),
            )));
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF232323),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.developer_mode, color: _primaryColor, size: 18),
              SizedBox(width: 8),
              Text(
                'DevConsole',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close,
                color: _textColor.withAlpha((0.7 * 255).round()), size: 18),
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F1F1F),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade800,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton(0, '日志'),
          _buildTabButton(1, 'API请求'),
          _buildTabButton(2, '埋点事件'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? _primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? _primaryColor
                    : _textColor.withAlpha((0.7 * 255).round()),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                decoration: TextDecoration.none, // 移除下划线
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    // 如果正在显示详情，则显示相应的详情视图
    if (_showingLogDetails && _currentLog != null) {
      return _buildLogDetailsView(_currentLog!);
    } else if (_showingApiDetails && _currentApiRequest != null) {
      return _buildApiDetailsView(_currentApiRequest!);
    } else if (_showingDetails && _currentDetailEvent != null) {
      return _buildEventDetailsView(_currentDetailEvent!);
    }

    // 否则显示正常的标签页内容
    switch (_selectedTabIndex) {
      case 0:
        return _buildLogsTab();
      case 1:
        return _buildApiMonitorTab();
      case 2:
        return _buildEventsTab();
      default:
        return Container();
    }
  }

  // 构建日志管理标签页
  Widget _buildLogsTab() {
    final logs = widget.logManager.getLogs();

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '没有日志记录',
              style: TextStyle(
                color: _textColor.withAlpha((0.7 * 255).round()),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 生成测试日志
                widget.logManager.generateTestLogs();
                setState(() {});
              },
              child: Text('添加测试日志'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 标题和操作按钮
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '日志数量: ${logs.length}',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.logManager.clearLogs();
                  setState(() {});
                },
                child: Text(
                  '清除所有',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 日志列表（简化版）
        Expanded(
          child: ListView.builder(
            itemCount: logs.length,
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 4),
            itemBuilder: (context, index) {
              final log = logs[logs.length - 1 - index]; // 最新的日志在前面
              final level = log['level'] as LogLevel;
              final message = log['message'] as String;
              final tag = log['tag'] as String;
              final time = log['time'] as DateTime;
              final timeStr =
                  "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";

              Color levelColor;
              IconData levelIcon;

              switch (level) {
                case LogLevel.debug:
                  levelColor = Colors.grey;
                  levelIcon = Icons.bug_report;
                  break;
                case LogLevel.info:
                  levelColor = Colors.blue;
                  levelIcon = Icons.info;
                  break;
                case LogLevel.warning:
                  levelColor = Colors.orange;
                  levelIcon = Icons.warning;
                  break;
                case LogLevel.error:
                  levelColor = Colors.red;
                  levelIcon = Icons.error;
                  break;
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: Color(0xFF1F1F1F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade800, width: 0.5),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentLog = log;
                      _showingLogDetails = true;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          levelIcon,
                          color: levelColor,
                          size: 20,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.length > 50
                                    ? '${message.substring(0, 50)}...'
                                    : message,
                                style: TextStyle(
                                  color: _textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '[$timeStr] $tag',
                                style: TextStyle(
                                  color:
                                      _textColor.withAlpha((0.7 * 255).round()),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: _textColor.withAlpha((0.54 * 255).round()),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 构建API监控标签页（简化版）
  Widget _buildApiMonitorTab() {
    final requests = widget.apiMonitor.getRequests();

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '没有API请求记录',
              style: TextStyle(
                color: _textColor.withAlpha((0.7 * 255).round()),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 生成测试请求
                widget.apiMonitor.generateTestRequests();
                setState(() {});
              },
              child: Text('添加测试请求'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 标题和操作按钮
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '请求数量: ${requests.length}',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.apiMonitor.clearRequests();
                  setState(() {});
                },
                child: Text(
                  '清除所有',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 请求列表（简化版）
        Expanded(
          child: ListView.builder(
            itemCount: requests.length,
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 4),
            itemBuilder: (context, index) {
              final request = requests[index];
              final url = request['url'] as String;
              final method = request['method'] as String;
              final status = request['status'] as RequestStatus;
              final statusCode = request['statusCode'] as int?;
              final duration = request['duration'] as int?;

              Color statusColor;
              IconData statusIcon;

              switch (status) {
                case RequestStatus.pending:
                  statusColor = Colors.blue;
                  statusIcon = Icons.hourglass_empty;
                  break;
                case RequestStatus.success:
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case RequestStatus.failed:
                  statusColor = Colors.red;
                  statusIcon = Icons.error;
                  break;
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: Color(0xFF1F1F1F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade800, width: 0.5),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentApiRequest = request;
                      _showingApiDetails = true;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: 20,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getMethodColor(method),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      method,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  if (statusCode != null)
                                    Text(
                                      '$statusCode',
                                      style: TextStyle(
                                        color: _getStatusCodeColor(statusCode),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (duration != null)
                                    Text(
                                      ' (${duration}ms)',
                                      style: TextStyle(
                                        color: _textColor
                                            .withAlpha((0.7 * 255).round()),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                url.length > 50
                                    ? '${url.substring(0, 50)}...'
                                    : url,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: _textColor.withAlpha((0.54 * 255).round()),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 构建埋点事件标签页（简化版）
  Widget _buildEventsTab() {
    final events = widget.eventTracker.getEvents();

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '没有埋点事件记录',
              style: TextStyle(
                color: _textColor.withAlpha((0.7 * 255).round()),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 生成测试事件
                widget.eventTracker.generateTestEvents();
                setState(() {});
              },
              child: Text('添加测试事件'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 标题和操作按钮
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '事件数量: ${events.length}',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.eventTracker.clearEvents();
                  setState(() {});
                },
                child: Text(
                  '清除所有',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 事件列表
        Expanded(
          child: ListView.builder(
            itemCount: events.length,
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 4),
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventItem(event);
            },
          ),
        ),
      ],
    );
  }

  // 构建日志详情视图（简化版）
  Widget _buildLogDetailsView(Map<String, dynamic> log) {
    final level = log['level'] as LogLevel;
    final message = log['message'] as String;
    final tag = log['tag'] as String;
    final time = log['time'] as DateTime;
    final stackTrace = log['stackTrace'] as String?;
    final error = log['error'] as String?;

    // 格式化时间
    final timeStr =
        "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} "
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";

    // 获取日志级别的颜色和图标
    Color levelColor;
    IconData levelIcon;
    String levelName;

    switch (level) {
      case LogLevel.debug:
        levelColor = Colors.grey;
        levelIcon = Icons.bug_report;
        levelName = "调试";
        break;
      case LogLevel.info:
        levelColor = Colors.blue;
        levelIcon = Icons.info;
        levelName = "信息";
        break;
      case LogLevel.warning:
        levelColor = Colors.orange;
        levelIcon = Icons.warning;
        levelName = "警告";
        break;
      case LogLevel.error:
        levelColor = Colors.red;
        levelIcon = Icons.error;
        levelName = "错误";
        break;
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部操作栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notes, color: _textColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '日志详情',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: _textColor, size: 20),
                onPressed: () {
                  setState(() {
                    _showingLogDetails = false;
                    _currentLog = null;
                  });
                },
              ),
            ],
          ),

          SizedBox(height: 16),

          // 详情内容
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息卡片
                  Card(
                    color: Color(0xFF1F1F1F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade800, width: 0.5),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(levelIcon, color: levelColor, size: 24),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      levelColor.withAlpha((0.2 * 255).round()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  levelName,
                                  style: TextStyle(
                                    color: levelColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Spacer(),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color:
                                      _textColor.withAlpha((0.7 * 255).round()),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '标签: ',
                                style: TextStyle(
                                  color:
                                      _textColor.withAlpha((0.7 * 255).round()),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _primaryColor
                                      .withAlpha((0.2 * 255).round()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text(
                            '消息:',
                            style: TextStyle(
                              color: _textColor.withAlpha((0.7 * 255).round()),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              message,
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 错误信息（如果有）
                  if (error != null) ...[
                    SizedBox(height: 16),
                    Card(
                      color: Color(0xFF1F1F1F),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side:
                            BorderSide(color: Colors.grey.shade800, width: 0.5),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '错误信息',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: Colors.red.shade300,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 堆栈信息（如果有）
                  if (stackTrace != null) ...[
                    SizedBox(height: 16),
                    Card(
                      color: Color(0xFF1F1F1F),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side:
                            BorderSide(color: Colors.grey.shade800, width: 0.5),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.stacked_line_chart,
                                    color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '堆栈跟踪',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                stackTrace,
                                style: TextStyle(
                                  color:
                                      _textColor.withAlpha((0.8 * 255).round()),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建API请求详情视图
  Widget _buildApiDetailsView(Map<String, dynamic> request) {
    final url = request['url'] as String;
    final method = request['method'] as String;
    final headers = request['headers'] as Map<String, dynamic>?;
    final data = request['data'];
    final queryParameters = request['queryParameters'] as Map<String, dynamic>?;
    final statusCode = request['statusCode'] as int?;
    final response = request['response'];
    final error = request['error'] as String?;
    final status = request['status'] as RequestStatus;
    final duration = request['duration'] as int;

    // 获取请求状态的颜色和图标
    Color statusColor;
    IconData statusIcon;
    String statusName;

    switch (status) {
      case RequestStatus.pending:
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
        statusName = "进行中";
        break;
      case RequestStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusName = "成功";
        break;
      case RequestStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusName = "失败";
        break;
    }

    // 获取HTTP方法的颜色
    Color methodColor = _getMethodColor(method);

    // 获取状态码的颜色
    Color statusCodeColor =
        statusCode != null ? _getStatusCodeColor(statusCode) : Colors.grey;

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部操作栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.language, color: _textColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'API请求详情',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: _textColor, size: 20),
                onPressed: () {
                  setState(() {
                    _showingApiDetails = false;
                    _currentApiRequest = null;
                  });
                },
              ),
            ],
          ),

          SizedBox(height: 16),

          // 详情内容
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 请求基本信息卡片
                  Card(
                    color: Color(0xFF1F1F1F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade800, width: 0.5),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 状态和方法
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 24),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor
                                      .withAlpha((0.2 * 255).round()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusName,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: methodColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  method,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (statusCode != null) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusCodeColor
                                        .withAlpha((0.2 * 255).round()),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$statusCode',
                                    style: TextStyle(
                                      color: statusCodeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                              Spacer(),
                              Text(
                                '${duration}ms',
                                style: TextStyle(
                                  color:
                                      _textColor.withAlpha((0.7 * 255).round()),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // URL
                          Text(
                            'URL:',
                            style: TextStyle(
                              color: _textColor.withAlpha((0.7 * 255).round()),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              url,
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // 请求详情
                  Card(
                    color: Color(0xFF1F1F1F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade800, width: 0.5),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '请求详情',
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),

                          // 请求头
                          if (headers != null && headers.isNotEmpty) ...[
                            Text(
                              '请求头:',
                              style: TextStyle(
                                color:
                                    _textColor.withAlpha((0.7 * 255).round()),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatJson(headers),
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],

                          // 查询参数
                          if (queryParameters != null &&
                              queryParameters.isNotEmpty) ...[
                            Text(
                              '查询参数:',
                              style: TextStyle(
                                color:
                                    _textColor.withAlpha((0.7 * 255).round()),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatJson(queryParameters),
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],

                          // 请求数据
                          if (data != null) ...[
                            Text(
                              '请求数据:',
                              style: TextStyle(
                                color:
                                    _textColor.withAlpha((0.7 * 255).round()),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatValue(data),
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // 响应详情
                  Card(
                    color: Color(0xFF1F1F1F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade800, width: 0.5),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                status == RequestStatus.success
                                    ? Icons.download_done
                                    : Icons.error_outline,
                                color: status == RequestStatus.success
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '响应详情',
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // 错误信息
                          if (error != null) ...[
                            Text(
                              '错误信息:',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: Colors.red.shade300,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],

                          // 响应数据
                          if (response != null) ...[
                            SizedBox(height: error != null ? 16 : 0),
                            Text(
                              '响应数据:',
                              style: TextStyle(
                                color:
                                    _textColor.withAlpha((0.7 * 255).round()),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatValue(response),
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建埋点事件详情视图
  Widget _buildEventDetailsView(Map<String, dynamic> event) {
    final name = event['name'] as String;
    final category = event['category'] as String;
    final time = event['time'] as DateTime;
    final parameters = event['parameters'] as Map<String, dynamic>?;
    final status = event['status'] as EventStatus;
    final errorMessage = event['errorMessage'] as String?;
    final id = event['id'] as String;

    // 格式化时间
    final timeStr =
        "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} "
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";

    // 获取状态的颜色和图标
    Color statusColor;
    IconData statusIcon;
    String statusName;

    switch (status) {
      case EventStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusName = "待上传";
        break;
      case EventStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusName = "成功";
        break;
      case EventStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusName = "失败";
        break;
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部操作栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: _textColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '埋点事件详情',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: _textColor, size: 20),
                onPressed: () {
                  setState(() {
                    _showingDetails = false;
                    _currentDetailEvent = null;
                  });
                },
              ),
            ],
          ),

          SizedBox(height: 16),

          // 详情内容
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息卡片
                  Card(
                    color: Color(0xFF1F1F1F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade800, width: 0.5),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 24),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor
                                      .withAlpha((0.2 * 255).round()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusName,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Spacer(),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color:
                                      _textColor.withAlpha((0.7 * 255).round()),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '事件ID: ',
                                style: TextStyle(
                                  color:
                                      _textColor.withAlpha((0.7 * 255).round()),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  id,
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '事件名称: ',
                                style: TextStyle(
                                  color:
                                      _textColor.withAlpha((0.7 * 255).round()),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                name,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '分类: ',
                                style: TextStyle(
                                  color:
                                      _textColor.withAlpha((0.7 * 255).round()),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _primaryColor
                                      .withAlpha((0.2 * 255).round()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 参数信息（如果有）
                  if (parameters != null && parameters.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Card(
                      color: Color(0xFF1F1F1F),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side:
                            BorderSide(color: Colors.grey.shade800, width: 0.5),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.data_object,
                                    color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '事件参数',
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatJson(parameters),
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 错误信息（如果有）
                  if (errorMessage != null) ...[
                    SizedBox(height: 16),
                    Card(
                      color: Color(0xFF1F1F1F),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side:
                            BorderSide(color: Colors.grey.shade800, width: 0.5),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '错误信息',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                  color: Colors.red.shade300,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 格式化JSON对象
  String _formatJson(Map<String, dynamic> json) {
    try {
      // 简单格式化JSON
      final buffer = StringBuffer();
      json.forEach((key, value) {
        buffer.writeln('$key: ${_formatValue(value)}');
      });
      return buffer.toString();
    } catch (e) {
      return json.toString();
    }
  }

  // 格式化值
  String _formatValue(dynamic value) {
    if (value is Map) {
      final buffer = StringBuffer();
      buffer.writeln('{');
      value.forEach((k, v) {
        buffer.writeln('  $k: ${_formatValue(v)}');
      });
      buffer.writeln('}');
      return buffer.toString();
    } else if (value is List) {
      final buffer = StringBuffer();
      buffer.writeln('[');
      for (var item in value) {
        buffer.writeln('  ${_formatValue(item)},');
      }
      buffer.writeln(']');
      return buffer.toString();
    } else {
      return value?.toString() ?? 'null';
    }
  }

  // 获取HTTP方法的颜色
  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // 获取状态码的颜色
  Color _getStatusCodeColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return Colors.green;
    } else if (statusCode >= 300 && statusCode < 400) {
      return Colors.blue;
    } else if (statusCode >= 400 && statusCode < 500) {
      return Colors.orange;
    } else if (statusCode >= 500) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  // 在事件列表项中添加状态显示
  Widget _buildEventItem(Map<String, dynamic> event) {
    final name = event['name'] as String;
    final category = event['category'] as String;
    final time = event['time'] as DateTime;
    final status = event['status'] as EventStatus;
    final timeStr =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case EventStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case EventStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case EventStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Color(0xFF1F1F1F),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade800, width: 0.5),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentDetailEvent = event;
            _showingDetails = true;
          });
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: _textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primaryColor.withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: _textColor.withAlpha((0.7 * 255).round()),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: _textColor.withAlpha((0.54 * 255).round()),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
