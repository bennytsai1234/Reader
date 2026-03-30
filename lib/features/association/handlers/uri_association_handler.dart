import 'package:flutter/material.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'association_base.dart';

/// AssociationHandlerService 的 URI 解析邏輯擴展
mixin UriAssociationHandler on AssociationBase {
  void handleUri(BuildContext context, Uri uri, Function(BuildContext, String, String) showDialog) {
    AppLog.d('處理 Deep Link: $uri');
    if (uri.scheme == 'legado') {
      if (uri.host == 'import') {
        final type = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : 'auto';
        final src = uri.queryParameters['src'];
        if (src != null) {
          showDialog(context, type, src);
        }
      } else if (uri.host == 'addBook') {
        final url = uri.queryParameters['url'];
        if (url != null) {
          showDialog(context, 'book', url);
        }
      }
    }
  }
}

