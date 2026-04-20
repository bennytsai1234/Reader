import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inkpage_reader/core/constant/prefer_key.dart';

class ClickActionConfigPage extends StatefulWidget {
  const ClickActionConfigPage({super.key});

  @override
  State<ClickActionConfigPage> createState() => _ClickActionConfigPageState();
}

class _ClickActionConfigPageState extends State<ClickActionConfigPage> {
  static const Map<int, String> _actionNames = <int, String>{
    0: '喚起選單',
    1: '下一頁',
    2: '上一頁',
    3: '下一章',
    4: '上一章',
    5: '朗讀',
    7: '書籤',
  };
  static const List<int> _defaultActions = <int>[0, 0, 0, 0, 0, 0, 0, 0, 0];

  bool _isLoading = true;
  List<int> _actions = List<int>.from(_defaultActions);

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(PreferKey.readerClickActions);
    final parsed = _parseActions(stored);
    if (!mounted) return;
    setState(() {
      _actions = parsed;
      _isLoading = false;
    });
  }

  List<int> _parseActions(String? stored) {
    if (stored == null || stored.trim().isEmpty) {
      return List<int>.from(_defaultActions);
    }
    final values =
        stored
            .split(',')
            .map((item) => int.tryParse(item.trim()))
            .whereType<int>()
            .toList();
    if (values.length != 9) {
      return List<int>.from(_defaultActions);
    }
    return values;
  }

  Future<void> _saveActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferKey.readerClickActions, _actions.join(','));
  }

  Future<void> _resetActions() async {
    setState(() {
      _actions = List<int>.from(_defaultActions);
    });
    await _saveActions();
  }

  Future<void> _updateAction(int index, int action) async {
    setState(() {
      _actions[index] = action;
    });
    await _saveActions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('點擊區域設置'),
        actions: [
          TextButton(
            onPressed: () => _resetActions(),
            child: const Text('恢復預設', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '預設為九宮格全部喚起選單，可逐格改成翻頁、換章、朗讀或書籤。',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: 9,
                        itemBuilder: (ctx, index) {
                          return InkWell(
                            onTap: () => _showActionSelector(context, index),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.5),
                                ),
                                color: Colors.blue.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '區域 ${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _actionNames[_actions[index]] ?? '無功能',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  void _showActionSelector(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.5,
              ),
              child: ListView(
                shrinkWrap: true,
                children:
                    _actionNames.entries.map((entry) {
                      return ListTile(
                        title: Text(entry.value),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _updateAction(index, entry.key);
                        },
                      );
                    }).toList(),
              ),
            ),
          ),
    );
  }
}
