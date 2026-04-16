import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/core/models/dict_rule.dart';
import 'dict_provider.dart';

class DictRulePage extends StatefulWidget {
  const DictRulePage({super.key});

  @override
  State<DictRulePage> createState() => _DictRulePageState();
}

class _DictRulePageState extends State<DictRulePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DictProvider>().loadRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('字典規則管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
      body: Consumer<DictProvider>(
        builder: (context, provider, child) {
          if (provider.allRules.isEmpty) {
            return const Center(child: Text('暫無規則'));
          }
          return ListView.separated(
            itemCount: provider.allRules.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final rule = provider.allRules[index];
              return ListTile(
                title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(rule.urlRule, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: rule.enabled,
                      onChanged: (val) => provider.toggleRule(rule),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditDialog(context, rule: rule),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => provider.deleteRule(rule),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, {DictRule? rule}) {
    final nameController = TextEditingController(text: rule?.name ?? '');
    final urlController = TextEditingController(text: rule?.urlRule ?? '');
    final showController = TextEditingController(text: rule?.showRule ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(rule == null ? '新增規則' : '編輯規則')),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: '複製規則',
              onPressed: () {
                final r = DictRule(
                  name: nameController.text,
                  urlRule: urlController.text,
                  showRule: showController.text,
                );
                Clipboard.setData(ClipboardData(text: jsonEncode(r.toJson())));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已複製到剪貼簿')));
              },
            ),
            IconButton(
              icon: const Icon(Icons.paste, size: 20),
              tooltip: '貼上規則',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text;
                if (text != null && mounted) {
                  try {
                    final json = jsonDecode(text);
                    final r = DictRule.fromJson(json);
                    nameController.text = r.name;
                    urlController.text = r.urlRule;
                    showController.text = r.showRule;
                  } catch (e) {
                    messenger.showSnackBar(const SnackBar(content: Text('格式錯誤')));
                  }
                }
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '名稱'),
                readOnly: rule != null, // Name is PK
              ),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL 規則 (用 {{key}} 代替搜尋詞)'),
                maxLines: 3,
              ),
              TextField(
                controller: showController,
                decoration: const InputDecoration(labelText: '顯示規則 (選填)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRule = DictRule(
                name: nameController.text,
                urlRule: urlController.text,
                showRule: showController.text,
                enabled: rule?.enabled ?? true,
                sortNumber: rule?.sortNumber ?? 0,
              );
              context.read<DictProvider>().saveRule(newRule);
              Navigator.pop(context);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}

