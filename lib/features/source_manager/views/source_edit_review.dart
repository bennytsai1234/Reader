import 'package:flutter/material.dart';
import '../widgets/rule_text_field.dart';

class SourceEditReview extends StatelessWidget {
  final Map<String, TextEditingController> controllers;

  const SourceEditReview({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RuleTextField(controller: controllers['ruleReviewUrl']!, label: '評論網址', isUrl: true),
        RuleTextField(controller: controllers['ruleReviewAvatar']!, label: '頭像規則'),
        RuleTextField(controller: controllers['ruleReviewContent']!, label: '內容規則', maxLines: 2),
        RuleTextField(controller: controllers['ruleReviewPostTime']!, label: '發佈時間'),
      ],
    );
  }
}
