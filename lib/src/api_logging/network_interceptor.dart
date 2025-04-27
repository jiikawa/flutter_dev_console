import '../api_monitor.dart';

/// 网络请求拦截器接口
///
/// 定义了网络请求拦截器的基本功能，可以被不同HTTP客户端的具体实现类实现。
/// 通过抓包方式自动监听和记录API请求，不需要在业务代码中手动添加日志记录。
abstract class NetworkInterceptor {
  /// 获取API监视器实例
  ApiMonitor get apiMonitor;

  /// 记录请求开始
  ///
  /// [url] 请求URL
  /// [method] 请求方法
  /// [headers] 请求头
  /// [data] 请求数据
  /// [queryParameters] 查询参数
  ///
  /// 返回请求ID，用于后续更新请求状态
  String logRequestStart(
    String url,
    String method, {
    Map<String, dynamic>? headers,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return apiMonitor.addRequest(
      url,
      method,
      headers: headers,
      data: data,
      queryParameters: queryParameters,
      status: RequestStatus.pending,
    );
  }

  /// 记录请求成功
  ///
  /// [requestId] 请求ID
  /// [statusCode] 响应状态码
  /// [response] 响应数据
  void logRequestSuccess(
    String requestId,
    int? statusCode,
    dynamic response,
  ) {
    apiMonitor.updateRequest(
      requestId,
      statusCode: statusCode,
      response: response,
      status: RequestStatus.success,
    );
  }

  /// 记录请求失败
  ///
  /// [requestId] 请求ID
  /// [error] 错误信息
  /// [statusCode] 响应状态码
  void logRequestError(
    String requestId,
    String error, {
    int? statusCode,
  }) {
    apiMonitor.updateRequest(
      requestId,
      statusCode: statusCode,
      error: error,
      status: RequestStatus.failed,
    );
  }
}

/// Dio HTTP客户端的网络拦截器实现指南
///
/// 如果您使用Dio HTTP客户端，可以按照以下方式实现网络拦截器：
///
/// ```dart
/// import 'package:dio/dio.dart';
/// import 'package:flutter_dev_console/dev_console.dart';
///
/// class DioNetworkInterceptor extends Interceptor implements NetworkInterceptor {
///   @override
///   final ApiMonitor apiMonitor;
///
///   DioNetworkInterceptor({required this.apiMonitor});
///
///   @override
///   void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
///     // 记录请求开始
///     final requestId = logRequestStart(
///       options.uri.toString(),
///       options.method,
///       headers: options.headers,
///       data: options.data,
///       queryParameters: options.queryParameters,
///     );
///
///     // 在options中存储requestId，用于后续更新
///     options.extra['requestId'] = requestId;
///
///     super.onRequest(options, handler);
///   }
///
///   @override
///   void onResponse(Response response, ResponseInterceptorHandler handler) {
///     // 从options中获取requestId
///     final requestId = response.requestOptions.extra['requestId'] as String?;
///
///     if (requestId != null) {
///       // 记录请求成功
///       logRequestSuccess(
///         requestId,
///         response.statusCode,
///         response.data,
///       );
///     }
///
///     super.onResponse(response, handler);
///   }
///
///   @override
///   void onError(DioException err, ErrorInterceptorHandler handler) {
///     // 从options中获取requestId
///     final requestId = err.requestOptions.extra['requestId'] as String?;
///
///     if (requestId != null) {
///       // 记录请求失败
///       logRequestError(
///         requestId,
///         err.toString(),
///         statusCode: err.response?.statusCode,
///       );
///     }
///
///     super.onError(err, handler);
///   }
/// }
/// ```
///
/// 使用方式：
///
/// ```dart
/// final dio = Dio();
/// final apiMonitor = DevConsole.instance.getApiMonitor();
/// dio.interceptors.add(DioNetworkInterceptor(apiMonitor: apiMonitor));
/// ```

/// HTTP包的网络拦截器实现指南
///
/// 如果您使用dart:io中的HttpClient，可以按照以下方式实现网络拦截器：
///
/// ```dart
/// import 'dart:io';
/// import 'dart:convert';
/// import 'package:flutter_dev_console/dev_console.dart';
///
/// class HttpClientInterceptor implements NetworkInterceptor {
///   @override
///   final ApiMonitor apiMonitor;
///
///   final Map<HttpClientRequest, String> _requestIds = {};
///
///   HttpClientInterceptor({required this.apiMonitor});
///
///   HttpClient createClient() {
///     final client = HttpClient();
///
///     client.addRequestModifier((request) async {
///       // 记录请求开始
///       final requestId = logRequestStart(
///         request.uri.toString(),
///         request.method,
///         headers: request.headers.map((name, values) =>
///           MapEntry(name, values.join(', '))),
///       );
///
///       // 存储requestId，用于后续更新
///       _requestIds[request] = requestId;
///
///       return request;
///     });
///
///     client.addResponseModifier((request, response) async {
///       // 获取requestId
///       final requestId = _requestIds[request];
///
///       if (requestId != null) {
///         // 读取响应数据
///         final responseBody = await response.transform(utf8.decoder).join();
///
///         // 记录请求成功或失败
///         if (response.statusCode >= 200 && response.statusCode < 300) {
///           logRequestSuccess(
///             requestId,
///             response.statusCode,
///             responseBody,
///           );
///         } else {
///           logRequestError(
///             requestId,
///             'HTTP Error: ${response.statusCode}',
///             statusCode: response.statusCode,
///           );
///         }
///
///         // 移除requestId
///         _requestIds.remove(request);
///       }
///
///       return response;
///     });
///
///     return client;
///   }
/// }
/// ```
///
/// 使用方式：
///
/// ```dart
/// final interceptor = HttpClientInterceptor(apiMonitor: DevConsole.instance.getApiMonitor());
/// final client = interceptor.createClient();
/// // 使用client发起请求
/// ```

/// 网络拦截器工厂
///
/// 提供创建NetworkInterceptor实例的静态方法
class NetworkInterceptorFactory {
  /// 创建一个网络请求拦截器
  ///
  /// [apiMonitor] API监视器实例
  ///
  /// 注意：这是一个抽象接口，您需要根据自己使用的HTTP客户端实现具体的拦截器。
  /// 请参考上面的实现指南。
  static NetworkInterceptor create({required ApiMonitor apiMonitor}) {
    throw UnimplementedError('这是一个抽象接口，您需要根据自己使用的HTTP客户端实现具体的拦截器。'
        '请参考NetworkInterceptor类中的实现指南。');
  }
}
