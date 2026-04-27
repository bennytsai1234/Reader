import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inkpage_reader/features/bookshelf/bookshelf_provider.dart';
import 'package:inkpage_reader/core/models/book_group.dart';

class GroupManagePage extends StatefulWidget {
  const GroupManagePage({super.key});

  @override
  State<GroupManagePage> createState() => _GroupManagePageState();
}

class _GroupManagePageState extends State<GroupManagePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BookshelfProvider>(
      builder: (context, provider, child) {
        // 只顯示自定義分組 (排除 "全部" 與 "未分組")
        final customGroups =
            provider.groups.where((g) => g.groupId > 0).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('管理分組'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddGroupDialog(context, provider),
              ),
            ],
          ),
          body:
              customGroups.isEmpty
                  ? const Center(child: Text('目前沒有自定義分組'))
                  : ReorderableListView.builder(
                    itemCount: customGroups.length,
                    onReorder:
                        (oldIndex, newIndex) =>
                            provider.reorderGroups(oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final group = customGroups[index];
                      return ListTile(
                        key: ValueKey(group.groupId),
                        leading: _buildGroupCover(group),
                        title: Text(group.groupName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: group.show,
                              onChanged:
                                  (val) => provider.updateGroupVisibility(
                                    group.groupId,
                                    val,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed:
                                  () => _showRenameDialog(
                                    context,
                                    provider,
                                    group,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed:
                                  () => _showDeleteConfirm(
                                    context,
                                    provider,
                                    group,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        );
      },
    );
  }

  Widget _buildGroupCover(BookGroup group) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child:
          group.coverPath != null && group.coverPath!.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(File(group.coverPath!), fit: BoxFit.cover),
              )
              : const Icon(Icons.folder, color: Colors.blue),
    );
  }

  void _showAddGroupDialog(BuildContext context, BookshelfProvider provider) {
    final ctrl = TextEditingController();
    String? coverPath;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('新增分組'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (img != null) {
                            setDialogState(() => coverPath = img.path);
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child:
                              coverPath != null
                                  ? Image.file(
                                    File(coverPath!),
                                    fit: BoxFit.cover,
                                  )
                                  : const Icon(
                                    Icons.add_a_photo,
                                    color: Colors.grey,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(hintText: '輸入分組名稱'),
                        autofocus: true,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (ctrl.text.isNotEmpty) {
                          provider.createGroup(
                            ctrl.text.trim(),
                            coverPath: coverPath,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('新增'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    BookshelfProvider provider,
    BookGroup group,
  ) {
    final ctrl = TextEditingController(text: group.groupName);
    var coverPath = group.coverPath;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('編輯分組'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (img != null) {
                            setDialogState(() => coverPath = img.path);
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child:
                              coverPath != null
                                  ? Image.file(
                                    File(coverPath!),
                                    fit: BoxFit.cover,
                                  )
                                  : const Icon(
                                    Icons.add_a_photo,
                                    color: Colors.grey,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(hintText: '輸入新名稱'),
                        autofocus: true,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (ctrl.text.isNotEmpty) {
                          provider.renameGroup(
                            group.groupId,
                            ctrl.text.trim(),
                            coverPath: coverPath,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('確定'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    BookshelfProvider provider,
    BookGroup group,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('刪除分組'),
            content: Text('確定要刪除「${group.groupName}」嗎？分組內的書籍將變回未分組狀態。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  provider.deleteGroup(group.groupId);
                  Navigator.pop(ctx);
                },
                child: const Text('刪除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
