import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/local_book/local_book_formats.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/features/bookshelf/bookshelf_provider.dart';

/// FilePickerPage - 檔案瀏覽器 (原 Android FileManageActivity)
class FilePickerPage extends StatefulWidget {
  const FilePickerPage({super.key});

  @override
  State<FilePickerPage> createState() => _FilePickerPageState();
}

class _FilePickerPageState extends State<FilePickerPage> {
  Directory? _currentDir;
  List<FileSystemEntity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDefaultDir();
  }

  Future<void> _initDefaultDir() async {
    Directory? dir;
    if (Platform.isAndroid) {
      // 深度還原：Android 預設到外部儲存空間根目錄
      dir = Directory('/storage/emulated/0');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    _navigateTo(dir ?? Directory('/'));
  }

  Future<void> _navigateTo(Directory dir) async {
    setState(() => _isLoading = true);
    try {
      final list = await dir.list().toList();
      // 排序：目錄在前，檔案在後
      list.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      setState(() {
        _currentDir = dir;
        _entities = list;
        _isLoading = false;
      });
    } catch (e) {
      AppLog.e('Navigate to ${dir.path} failed: $e', error: e);
      setState(() => _isLoading = false);
    }
  }

  void _onEntityTap(FileSystemEntity entity) {
    if (entity is Directory) {
      _navigateTo(entity);
    } else if (entity is File) {
      if (isSupportedLocalBookExtension(p.extension(entity.path))) {
        _showImportConfirm(entity);
      }
    }
  }

  void _showImportConfirm(File file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('匯入書籍'),
        content: Text('確定要匯入「${p.basename(file.path)}」嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BookshelfProvider>().importLocalBookPath(file.path);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('匯入成功')));
                Navigator.pop(context); // 匯入後關閉瀏覽器
              }
            },
            child: const Text('匯入'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_currentDir != null) {
      final parent = _currentDir!.parent;
      // 限制不能超出 Documents 或 Root
      if (_currentDir!.path != parent.path && _currentDir!.path.length > 20) {
        _navigateTo(parent);
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentDir == null ? '檔案瀏覽' : p.basename(_currentDir!.path)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (!await _onWillPop()) return;
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    child: Text(
                      _currentDir?.path ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: _entities.isEmpty
                        ? const Center(child: Text('此目錄是空的'))
                        : ListView.builder(
                            itemCount: _entities.length,
                            itemBuilder: (context, index) {
                              final entity = _entities[index];
                              final isDir = entity is Directory;
                              final name = p.basename(entity.path);
                              
                              if (!isDir) {
                                if (!isSupportedLocalBookExtension(
                                  p.extension(entity.path),
                                )) {
                                  return const SizedBox.shrink();
                                }
                              }

                              return ListTile(
                                leading: Icon(
                                  isDir ? Icons.folder : (p.extension(entity.path) == '.epub' ? Icons.book : Icons.description),
                                  color: isDir ? Colors.amber : Colors.blueGrey,
                                ),
                                title: Text(name, style: TextStyle(fontSize: 14, fontWeight: isDir ? FontWeight.w500 : null)),
                                trailing: isDir ? const Icon(Icons.chevron_right, size: 16) : null,
                                onTap: () => _onEntityTap(entity),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
