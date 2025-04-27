import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dev_console/dev_console.dart';

void main() {
  // 初始化开发控制台
  DevConsole.instance.initialize(
    maxLogCount: 500,
    maxRequestCount: 100,
    theme: DevConsoleTheme(
      primaryColor: Colors.blue,
      backgroundColor: const Color(0xF0121212),
      textColor: Colors.white,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevConsole Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(decoration: TextDecoration.none),
          bodyMedium: TextStyle(decoration: TextDecoration.none),
          bodySmall: TextStyle(decoration: TextDecoration.none),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const DevConsoleDemo(),
    );
  }
}

class DevConsoleDemo extends StatefulWidget {
  const DevConsoleDemo({super.key});

  @override
  DevConsoleDemoState createState() => DevConsoleDemoState();
}

class DevConsoleDemoState extends State<DevConsoleDemo> {
  final Dio _dio = Dio();

  late ApiLogger _apiLogger;

  @override
  void initState() {
    super.initState();

    // 获取API日志记录器
    _apiLogger = DevConsole.instance.getApiLogger();

    // 配置Dio拦截器，手动记录API请求
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 请求前记录
        _apiLogger.logRequest(
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
        _apiLogger.logResponse(
          response.requestOptions.uri.toString(),
          response.requestOptions.method,
          response.statusCode,
          response.data,
        );
        return handler.next(response);
      },
      onError: (error, handler) {
        // 请求失败记录
        _apiLogger.logError(
          error.requestOptions.uri.toString(),
          error.requestOptions.method,
          error.toString(),
        );
        return handler.next(error);
      },
    ));

    // 注意：以上拦截器代码展示了如何手动使用ApiLogger记录请求
    // 不再依赖DevConsole的内置拦截器
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevConsole 示例'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // 显示开发控制台
                DevConsole.instance.show(context);
              },
              child: const Text('显示开发控制台'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addTestLogs,
              child: const Text('添加测试日志'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addTestApiRequests,
              child: const Text('添加测试API请求'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _makeRealApiRequest,
              child: const Text('发起真实API请求'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          DevConsole.instance.show(context);
        },
        tooltip: '开发控制台',
        child: const Icon(Icons.developer_mode),
      ),
    );
  }

  // 添加测试日志
  void _addTestLogs() {
    // 添加不同级别的日志
    DevConsole.instance.log('这是一条信息日志', level: LogLevel.info, tag: 'Example');
    DevConsole.instance.log('这是一条调试日志', level: LogLevel.debug, tag: 'Example');
    DevConsole.instance
        .log('这是一条警告日志', level: LogLevel.warning, tag: 'Example');

    // 添加带有堆栈信息的错误日志
    try {
      throw Exception('这是一个测试异常');
    } catch (e, stack) {
      DevConsole.instance.log('发生异常: $e',
          level: LogLevel.error, tag: 'Error', stackTrace: stack, error: e);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已添加测试日志')),
    );
  }

  // 添加测试API请求
  void _addTestApiRequests() {
    // 添加测试API请求
    DevConsole.instance.logApiRequest(
      'https://api.example.com/users',
      'GET',
      headers: {'Authorization': 'Bearer token123'},
      response: {'id': 1, 'name': 'Test User'},
      statusCode: 200,
    );

    DevConsole.instance.logApiRequest(
      'https://api.example.com/posts',
      'POST',
      data: {'title': 'New Post', 'content': 'Content'},
      response: {'id': 1, 'success': true},
      statusCode: 201,
    );

    DevConsole.instance.logApiRequest(
      'https://api.example.com/invalid',
      'GET',
      error: '404 Not Found',
      statusCode: 404,
      status: RequestStatus.failed,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已添加测试API请求')),
    );
  }

  // 发起真实API请求
  Future<void> _makeRealApiRequest() async {
    try {
      // 使用添加了拦截器的Dio实例发起请求
      // 这些请求会被自动记录到开发控制台
      await _dio.get('https://jsonplaceholder.typicode.com/posts/1');
      await _dio.get('https://jsonplaceholder.typicode.com/users/1');

      // 故意发起一个会失败的请求
      await _dio.get('https://jsonplaceholder.typicode.com/invalid');
    } catch (e) {
      // 错误已被拦截器记录，这里不需要额外处理
      if (kDebugMode) {
        print('有些请求可能失败，但已被记录');
      }
    }

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已发起真实API请求')),
    );
  }
}
