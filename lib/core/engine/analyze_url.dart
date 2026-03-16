import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:legado_reader/core/models/base_source.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';
import 'package:legado_reader/core/services/http_client.dart';
import 'package:legado_reader/core/engine/web_book/headless_webview_service.dart';
import 'package:legado_reader/core/network/str_response.dart';

/// AnalyzeUrl - URL 規則解析與請求建構 (原 Android AnalyzeUrl.kt)
class AnalyzeUrl {
  final String rawUrl;
  final String? key;
  final int? page;
  final String baseUrl;
  final BaseSource? source;
  final dynamic ruleData;
  final String? speakText;
  final int? speakSpeed;

  String ruleUrl = '';
  String url = '';
  String method = 'GET';
  final Map<String, String> headerMap = {};
  dynamic body;
  String? charset;
  bool useWebView = false;
  String? webJs;
  int webViewDelayTime = 0;

  AnalyzeUrl(
    this.rawUrl, {
    this.key,
    this.page,
    this.speakText,
    this.speakSpeed,
    this.baseUrl = '',
    this.source,
    this.ruleData,
  }) {
    _init();
  }

  void _init() {
    ruleUrl = rawUrl;
    // 1. 執行 @js, <js>
    _analyzeJs();
    // 2. 替換 {{js}} 和 <page,page>
    _replaceKeyPageJs();
    // 3. 解析 URL 選項 (如 ,{"method": "POST"})
    _analyzeUrlOptions();
  }

  void _analyzeJs() {
    final jsRegex = RegExp(r'@js:([\s\S]*?)$|<js>([\s\S]*?)</js>', caseSensitive: false);
    var result = ruleUrl;
    final matches = jsRegex.allMatches(ruleUrl);
    
    int lastEnd = 0;

    for (final match in matches) {
      final jsStr = match.group(1) ?? match.group(2) ?? '';
      final rule = AnalyzeRule(source: source, ruleData: ruleData);
      rule.key = key;
      rule.page = page ?? 1;
      final evalRes = rule.evalJS(jsStr, result);
      result = evalRes?.toString() ?? '';
      lastEnd = match.end;
    }
    
    if (lastEnd > 0) {
      ruleUrl = result;
    }
  }

  void _replaceKeyPageJs() {
    // 替換 {{js}}
    final innerJsRegex = RegExp(r'\{\{([\s\S]*?)\}\}');
    ruleUrl = ruleUrl.replaceAllMapped(innerJsRegex, (match) {
      final jsStr = match.group(1)!;
      final rule = AnalyzeRule(source: source, ruleData: ruleData);
      rule.key = key;
      rule.page = page ?? 1;
      return rule.evalJS(jsStr, null)?.toString() ?? '';
    });

    // 替換 <page1,page2,page3>
    if (page != null) {
      final pageRegex = RegExp(r'<(.*?)>');
      ruleUrl = ruleUrl.replaceAllMapped(pageRegex, (match) {
        final pages = match.group(1)!.split(',');
        if (page! <= pages.length) {
          return pages[page! - 1].trim();
        }
        return pages.last.trim();
      });
    }

    // 替換搜尋關鍵字
    if (key != null) {
      ruleUrl = ruleUrl.replaceAll('{{key}}', key!);
    }

    // 替換 TTS 關鍵字
    if (speakText != null) {
      ruleUrl = ruleUrl.replaceAll('{{speakText}}', speakText!);
    }
    if (speakSpeed != null) {
      ruleUrl = ruleUrl.replaceAll('{{speakSpeed}}', speakSpeed!.toString());
    }
  }

  void _analyzeUrlOptions() {
    final paramSplitRegex = RegExp(r'\s*,\s*(?=\{)');
    final match = paramSplitRegex.firstMatch(ruleUrl);
    
    if (match != null) {
      url = ruleUrl.substring(0, match.start).trim();
      final optionStr = ruleUrl.substring(match.end).trim();
      try {
        final Map<String, dynamic> options = jsonDecode(optionStr);
        method = (options['method'] ?? 'GET').toString().toUpperCase();
        if (options['headers'] != null) {
          (options['headers'] as Map).forEach((k, v) => headerMap[k.toString()] = v.toString());
        }
        body = options['body'];
        useWebView = options['webView'] == true || options['webView'] == 'true';
        webJs = options['webJs'];
        charset = options['charset'];
        webViewDelayTime = int.tryParse(options['webViewDelayTime']?.toString() ?? '0') ?? 0;
      } catch (e) {
        debugPrint('AnalyzeUrl options parse error: $e');
      }

    } else {
      url = ruleUrl.trim();
    }

    // 處理相對路徑
    if (!url.startsWith('http') && baseUrl.isNotEmpty) {
      final baseUri = Uri.parse(baseUrl);
      url = baseUri.resolve(url).toString();
    }
  }

  /// 獲取回應內容 (對標 Android AnalyzeUrl.getStrResponseAwait)
  Future<StrResponse> getStrResponse() async {
    String finalBody = '';
    Response? rawResponse;

    // 如果開啟了 WebView 抓取模式
    if (useWebView) {
      finalBody = await HeadlessWebViewService().getRenderedHtml(
        url: url,
        headers: headerMap,
        js: webJs,
        delayTime: webViewDelayTime,
      );
      return StrResponse(
        url: url,
        body: finalBody,
        headers: {},
        raw: Response(requestOptions: RequestOptions(path: url), data: finalBody),
      );
    }

    final httpClient = HttpClient();
    final options = Options(
      method: method,
      headers: headerMap,
      responseType: ResponseType.plain,
    );

    if (method == 'POST') {
      rawResponse = await httpClient.client.post(url, data: body, options: options);
    } else {
      rawResponse = await httpClient.client.get(url, options: options);
    }

    return StrResponse(
      url: rawResponse.realUri.toString(),
      body: rawResponse.data?.toString() ?? '',
      headers: rawResponse.headers.map,
      raw: rawResponse,
    );
  }

  /// 獲取回應內容的 body (兼容舊代碼)
  Future<String> getResponseBody() async {
    final res = await getStrResponse();
    return res.body;
  }

  /// 獲取位元組回應內容
  Future<Uint8List> getByteArray() async {
    final httpClient = HttpClient();
    final options = Options(
      method: method,
      headers: headerMap,
      responseType: ResponseType.bytes,
    );

    Response<List<int>> response;
    if (method == 'POST') {
      response = await httpClient.client.post<List<int>>(url, data: body, options: options);
    } else {
      response = await httpClient.client.get<List<int>>(url, options: options);
    }

    return Uint8List.fromList(response.data ?? []);
  }
}
