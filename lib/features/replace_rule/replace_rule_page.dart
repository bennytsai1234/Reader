import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'replace_rule_provider.dart';
import 'package:inkpage_reader/core/models/replace_rule.dart';
import 'replace_rule_edit_page.dart';

class ReplaceRulePage extends StatelessWidget {
  const ReplaceRulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReplaceRuleProvider(),
      child: Consumer<ReplaceRuleProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('替換規則'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _navigateToEdit(context, provider),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'import') {
                      _showImportDialog(context, provider);
                    } else if (val == 'export') {
                      provider.exportToClipboard();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已複製至剪貼簿')));
                    } else if (val == 'test') {
                      _showTestDialog(context, provider);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'import', child: Text('從剪貼簿匯入')),
                    PopupMenuItem(value: 'export', child: Text('匯出至剪貼簿')),
                    PopupMenuItem(value: 'test', child: Text('即時測試')),
                  ],
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ReorderableListView.builder(
                    itemCount: provider.rules.length,
                    onReorder: provider.reorder,
                    itemBuilder: (context, index) {
                      final rule = provider.rules[index];
                      return _buildRuleItem(context, provider, rule, index);
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, ReplaceRuleProvider provider,
      ReplaceRule rule, int index) {
    return ListTile(
      key: ValueKey(rule.id),
      title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        '${rule.pattern} -> ${rule.replacement}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: rule.isEnabled,
            onChanged: (_) => provider.toggleEnabled(rule),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _navigateToEdit(context, provider, rule: rule),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _showDeleteConfirm(context, provider, rule),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context, ReplaceRuleProvider provider,
      {ReplaceRule? rule}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplaceRuleEditPage(
          rule: rule,
          onSave: (newRule) {
            if (rule == null) {
              provider.addRule(newRule);
            } else {
              provider.updateRule(newRule);
            }
          },
        ),
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, ReplaceRuleProvider provider, ReplaceRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除規則「${rule.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRule(rule.id);
              Navigator.pop(context);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, ReplaceRuleProvider provider) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      final count = await provider.importFromText(data.text!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功匯入 $count 個規則')));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('剪貼簿無內容')));
      }
    }
  }

  void _showTestDialog(BuildContext context, ReplaceRuleProvider provider) {
    final textCtrl = TextEditingController();
    var resultText = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('規則測試'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textCtrl,
                      decoration: const InputDecoration(hintText: '輸入測試文本', border: OutlineInputBorder()),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        var temp = textCtrl.text;
                        final enabledRules = provider.rules.where((r) => r.isEnabled).toList();
                        for (var rule in enabledRules) {
                          try {
                            if (rule.isRegex) {
                              final reg = RegExp(rule.pattern);
                              temp = temp.replaceAll(reg, rule.replacement);
                            } else {
                              temp = temp.replaceAll(rule.pattern, rule.replacement);
                            }
                          } catch (e) {
                            AppLog.d('規則執行失敗: $e');
                          }
                        }
                        setState(() {
                          resultText = temp;
                        });
                      },
                      child: const Text('執行啟用規則'),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: Text(resultText.isEmpty ? '測試結果將顯示於此' : resultText),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉')),
              ],
            );
          },
        );
      },
    );
  }
}

