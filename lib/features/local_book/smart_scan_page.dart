import 'dart:io';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/features/bookshelf/bookshelf_provider.dart';

class SmartScanPage extends StatefulWidget {
  const SmartScanPage({super.key});

  @override
  State<SmartScanPage> createState() => _SmartScanPageState();
}

class _SmartScanPageState extends State<SmartScanPage> {
  String? _currentPath;
  List<FileSystemEntity> _files = [];
  bool _isScanning = false;
  final Set<String> _selectedPaths = {};

  @override
  void initState() {
    super.initState();
    _loadLastPath();
  }

  Future<void> _loadLastPath() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPath = prefs.getString('last_scan_path');
    if (lastPath != null && await Directory(lastPath).exists()) {
      if (mounted) {
        setState(() => _currentPath = lastPath);
        _scanDirectory(lastPath);
      }
    }
  }

  Future<void> _pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_scan_path', result);
      if (mounted) {
        setState(() => _currentPath = result);
        _scanDirectory(result);
      }
    }
  }

  Future<void> _scanDirectory(String path) async {
    setState(() {
      _isScanning = true;
      _files = [];
      _selectedPaths.clear();
    });

    try {
      final dir = Directory(path);
      final entities = <FileSystemEntity>[];
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.txt' || ext == '.epub') {
            entities.add(entity);
          }
        }
      }
      if (mounted) {
        setState(() {
          _files = entities;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('掃描失敗: $e')));
      }
    }
  }

  void _toggleSelect(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  Future<void> _importSelected() async {
    if (_selectedPaths.isEmpty) return;

    var successCount = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    for (var path in _selectedPaths) {
      try {
        await context.read<BookshelfProvider>().importLocalBookPath(path);
        successCount++;
      } catch (e) {
        AppLog.e('匯入 $path 失敗: $e', error: e);
      }
    }

    if (mounted) {
      Navigator.pop(context); // 關閉 Loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功匯入 $successCount 本書籍')));
      Navigator.pop(context); // 返回書架
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智慧掃描'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _pickDirectory,
            tooltip: '選擇目錄',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentPath != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_currentPath!, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _isScanning
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('正在搜尋電子書...')]))
                : _files.isEmpty
                    ? Center(child: Text(_currentPath == null ? '請點擊右上角圖示選擇掃描目錄' : '此目錄下未找到 txt 或 epub 檔案'))
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index] as File;
                          final isSelected = _selectedPaths.contains(file.path);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) => _toggleSelect(file.path),
                            title: Text(p.basename(file.path)),
                            subtitle: Text(_formatSize(file)),
                            secondary: Icon(p.extension(file.path).toLowerCase() == '.epub' ? Icons.book : Icons.description, color: Colors.blueGrey),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedPaths.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton(
                  onPressed: _importSelected,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: Text('匯入已選 (${_selectedPaths.length})'),
                ),
              ),
            )
          : null,
    );
  }

  String _formatSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

