# DevConsole 开发控制台插件

DevConsole 是一个用于 Flutter 应用的开发调试工具，提供日志管理、接口请求监听和埋点事件查看功能。这个插件可以帮助开发者在开发和测试阶段更有效地调试应用。

## 功能特点

- **日志管理**：查看应用日志，支持不同级别（调试、信息、警告、错误），显示堆栈信息
- **接口监听**：监控所有网络请求，查看请求和响应详情，包括请求耗时统计
- **埋点事件**：查看埋点事件队列和历史记录

## 安装

将以下内容添加到你的 `pubspec.yaml` 文件中：

```yaml
dependencies:
  dev_console: ^0.1.0
```

或者，如果你想使用本地路径：

```yaml
dependencies:
  dev_console:
    path: ../path/to/dev_console
```

然后运行：

```bash
flutter pub get
```

## 使用方法

### 1. 初始化

在应用启动时初始化 DevConsole：

```dart
import 'package:dev_console/dev_console.dart';

void main() {
  // 初始化开发控制台
  DevConsole.instance.initialize();
  
  runApp(MyApp());
}
```

### 2. 记录 API 请求

你可以使用 ApiLogger 记录网络请求，适用于任何 HTTP 客户端：

```dart
import 'package:dev_console/dev_console.dart';

void setupApiLogging() {
  final apiLogger = DevConsole.instance.getApiLogger();
  
  // 在你的网络请求代码中添加以下记录
  
  // 1. 记录请求开始
  apiLogger.logRequest(
    'https://api.example.com/users',
    'GET',
    headers: {'Authorization': 'Bearer token123'},
    data: {'param': 'value'},
    queryParameters: {'page': '1'},
  );
  
  // 2. 记录请求成功
  apiLogger.logResponse(
    'https://api.example.com/users',
    'GET',
    200,
    {'id': 1, 'name': 'Test User'},
    headers: {'Content-Type': 'application/json'},
    data: {'param': 'value'},
    queryParameters: {'page': '1'},
  );
  
  // 3. 记录请求失败
  apiLogger.logError(
    'https://api.example.com/invalid',
    'GET',
    '404 Not Found',
    statusCode: 404,
    headers: {'Authorization': 'Bearer token123'},
    data: null,
    queryParameters: {},
  );
}
```

#### 适配不同 HTTP 客户端

以下是在几种常见 HTTP 客户端中集成 ApiLogger 的示例：

**http 包**

```dart
import 'package:http/http.dart' as http;
import 'package:dev_console/dev_console.dart';

Future<void> makeRequest() async {
  final apiLogger = DevConsole.instance.getApiLogger();
  final url = Uri.parse('https://api.example.com/users');
  final headers = {'Authorization': 'Bearer token123'};
  
  // 记录请求
  apiLogger.logRequest(
    url.toString(),
    'GET',
    headers: headers,
  );
  
  try {
    final response = await http.get(url, headers: headers);
    
    // 记录响应
    apiLogger.logResponse(
      url.toString(),
      'GET',
      response.statusCode,
      response.body,
      headers: headers,
    );
  } catch (error) {
    // 记录错误
    apiLogger.logError(
      url.toString(),
      'GET',
      error.toString(),
      headers: headers,
    );
  }
}
```

**Dio 包**

```dart
import 'package:dio/dio.dart';
import 'package:dev_console/dev_console.dart';

Future<void> setupDio() async {
  final dio = Dio();
  final apiLogger = DevConsole.instance.getApiLogger();
  
  // 添加拦截器
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // 请求前记录
      apiLogger.logRequest(
        options.uri.toString(),
        options.method,
        headers: options.headers,
        data: options.data,
        queryParameters: options.queryParameters,
      );
      return handler.next(options);
    },
    onResponse: (response, handler) {
      // 请求成功记录
      apiLogger.logResponse(
        response.requestOptions.uri.toString(),
        response.requestOptions.method,
        response.statusCode,
        response.data,
        headers: response.headers.map,
        data: response.requestOptions.data,
        queryParameters: response.requestOptions.queryParameters,
      );
      return handler.next(response);
    },
    onError: (error, handler) {
      // 请求失败记录
      apiLogger.logError(
        error.requestOptions.uri.toString(),
        error.requestOptions.method,
        error.toString(),
        statusCode: error.response?.statusCode,
        headers: error.requestOptions.headers,
        data: error.requestOptions.data,
        queryParameters: error.requestOptions.queryParameters,
      );
      return handler.next(error);
    },
  ));
}
```

### 3. 显示控制台

在需要时显示开发控制台：

```dart
ElevatedButton(
  onPressed: () {
    DevConsole.instance.show(context);
  },
  child: Text('显示开发控制台'),
)
```

或者添加一个悬浮按钮：

```dart
FloatingActionButton(
  onPressed: () {
    DevConsole.instance.show(context);
  },
  child: Icon(Icons.developer_mode),
  tooltip: '开发控制台',
)
```

### 4. 记录日志

使用 DevConsole 记录日志：

```dart
// 记录普通日志
DevConsole.instance.log('这是一条信息日志', level: LogLevel.info, tag: 'MyTag');

// 记录调试日志
DevConsole.instance.log('这是一条调试日志', level: LogLevel.debug, tag: 'Debug');

// 记录警告日志
DevConsole.instance.log('这是一条警告日志', level: LogLevel.warning, tag: 'Warning');

// 记录带有堆栈信息的错误日志
try {
  // 可能抛出异常的代码
  throw Exception('发生错误');
} catch (e, stack) {
  DevConsole.instance.log(
    '发生异常: $e', 
    level: LogLevel.error, 
    tag: 'Error', 
    stackTrace: stack, 
    error: e
  );
}
```

### 5. 快捷 API 记录方法

你可以使用 DevConsole 的简便方法快速记录 API 请求：

```dart
// 记录成功的请求
DevConsole.instance.logApiRequest(
  'https://api.example.com/users',
  'GET',
  headers: {'Authorization': 'Bearer token123'},
  response: {'id': 1, 'name': 'Test User'},
  statusCode: 200,
);

// 记录失败的请求
DevConsole.instance.logApiRequest(
  'https://api.example.com/invalid',
  'GET',
  error: '404 Not Found',
  statusCode: 404,
  status: RequestStatus.failed,
);
```

### 6. 记录埋点事件

使用DevConsole记录和跟踪埋点事件：

```dart
// 记录待上传的埋点事件
String eventId = DateTime.now().millisecondsSinceEpoch.toString();
DevConsole.instance.trackEvent(
  '页面浏览',
  parameters: {'page_name': '首页'},
  category: '页面',
  status: EventStatus.pending, // 默认为pending状态
);

// 上传成功后更新状态
DevConsole.instance.updateEventStatus(eventId, EventStatus.success);

// 上传失败后更新状态
DevConsole.instance.updateEventStatus(
  eventId, 
  EventStatus.failed,
  errorMessage: '网络连接超时',
);
```

## 配置选项

你可以在初始化时配置 DevConsole：

```dart
DevConsole.instance.initialize(
  maxLogCount: 500,      // 最大日志数量
  maxRequestCount: 100,  // 最大请求记录数量
  enableInRelease: false, // 是否在发布版本中启用
);
```

## 在发布版本中禁用

建议在发布版本中禁用 DevConsole，可以使用以下方式：

```dart
void main() {
  // 仅在调试模式下初始化
  if (kDebugMode) {
    DevConsole.instance.initialize();
  }
  
  runApp(MyApp());
}
```

## 自定义主题

你可以自定义控制台的主题：

```dart
DevConsole.instance.initialize(
  theme: DevConsoleTheme(
    primaryColor: Colors.blue,
    backgroundColor: Colors.grey[900],
    textColor: Colors.white,
  ),
);
```

## 注意事项

- 此插件仅用于开发和测试环境，不建议在生产环境中使用
- 日志和请求记录存储在内存中，应用重启后会清空
- 可以与任何HTTP客户端库集成，不限于特定的网络请求框架

## 贡献

欢迎提交 Issues 和 Pull Requests！

## 许可证

MIT