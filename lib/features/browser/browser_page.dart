import 'package:flutter/material.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:legado_reader/core/services/source_verification_service.dart';
import 'browser_params.dart';
import 'browser_provider.dart';

class BrowserPage extends StatefulWidget {
  final BrowserParams params;

  const BrowserPage({super.key, required this.params});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _isCloudflareChallenge = false;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams webViewParams;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      webViewParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      webViewParams = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(webViewParams);

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100;
              });
            }
          },
          onPageStarted: (String url) {
            AppLog.d('Page started loading: $url');
          },
          onPageFinished: (String url) async {
            AppLog.d('Page finished loading: $url');
            _checkCloudflare();
          },
          onWebResourceError: (WebResourceError error) {
            AppLog.e('Web resource error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('legado://') || request.url.startsWith('yuedu://')) {
              // TODO: 呼叫 AssociationHandlerService 處理自定義協議
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _checkCloudflare() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        '!!window._cf_chl_opt'
      );
      if (result == true || result.toString() == 'true') {
        _isCloudflareChallenge = true;
      } else if (_isCloudflareChallenge && widget.params.sourceVerificationEnable) {
        // Cloudflare 挑戰完成，自動觸發保存
        _handleOk();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _handleOk() async {
    if (!mounted) return;
    final provider = Provider.of<BrowserProvider>(context, listen: false);
    final html = await _controller.runJavaScriptReturningResult(
      'document.documentElement.outerHTML'
    );
    
    var finalHtml = html.toString();
    // 移除 runJavaScriptReturningResult 可能產生的雙引號
    if (finalHtml.startsWith('"') && finalHtml.endsWith('"')) {
      finalHtml = finalHtml.substring(1, finalHtml.length - 1);
    }

    await provider.saveVerificationResult(finalHtml);
    
    if (widget.params.verificationRequest != null) {
      SourceVerificationService().sendResult(
        widget.params.verificationRequest!, 
        finalHtml
      );
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final p = BrowserProvider(widget.params);
        p.init().then((_) {
          if (p.baseUrl != null) {
            if (p.html != null) {
              _controller.loadHtmlString(p.html!, baseUrl: p.baseUrl);
            } else {
              _controller.loadRequest(
                Uri.parse(p.baseUrl!),
                headers: p.headerMap,
              );
            }
          }
        });
        return p;
      },
      child: Consumer<BrowserProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.params.title, style: const TextStyle(fontSize: 16)),
                  if (widget.params.sourceName != null)
                    Text(
                      widget.params.sourceName!, 
                      style: const TextStyle(fontSize: 11, color: Colors.white70)
                    ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _handleOk,
                  tooltip: '完成驗證',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    final navigator = Navigator.of(context);
                    switch (value) {
                      case 'refresh':
                        _controller.reload();
                        break;
                      case 'disable':
                        provider.disableSource().then((_) {
                          if (mounted) navigator.pop();
                        });
                        break;
                      case 'delete':
                        provider.deleteSource().then((_) {
                          if (mounted) navigator.pop();
                        });
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'refresh', child: Text('重新整理')),
                    if (widget.params.sourceOrigin != null) ...[
                      const PopupMenuItem(value: 'disable', child: Text('停用此源')),
                      const PopupMenuItem(
                        value: 'delete', 
                        child: Text('刪除此源', style: TextStyle(color: Colors.red))
                      ),
                    ],
                  ],
                ),
              ],
              bottom: _progress < 1.0
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(2),
                      child: LinearProgressIndicator(
                        value: _progress, 
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                  : null,
            ),
            body: WebViewWidget(controller: _controller),
          );
        },
      ),
    );
  }
}

