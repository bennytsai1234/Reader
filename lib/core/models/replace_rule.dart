
/// ReplaceRule - 替換淨化規則模型
/// (原 Android data/entities/ReplaceRule.kt)
class ReplaceRule {
  int id;
  String name; // 規則名稱
  String? group; // 分組
  String pattern; // 替換正則內容
  String replacement; // 替換為內容
  String? scope; // 作用範圍 (書名/書源URL)
  bool scopeTitle; // 是否作用於標題
  bool scopeContent; // 是否作用於正文
  String? excludeScope; // 排除範圍
  bool isEnabled; // 是否啟用
  bool isRegex; // 是否為正則
  int timeoutMillisecond; // 正則執行超時 (ms)
  int order; // 排序序號 (原 Android sortOrder)

  ReplaceRule({
    this.id = 0,
    this.name = '',
    this.group,
    this.pattern = '',
    this.replacement = '',
    this.scope,
    this.scopeTitle = false,
    this.scopeContent = true,
    this.excludeScope,
    this.isEnabled = true,
    this.isRegex = true,
    this.timeoutMillisecond = 3000,
    this.order = 0,
  });

  /// 校驗規則是否合法 (原 Android isValid)
  bool isValid() {
    if (pattern.isEmpty) return false;
    if (isRegex) {
      try {
        RegExp(pattern);
      } catch (_) {
        return false;
      }
      // 檢查結尾是否有多餘的 | (原版特有的健壯性檢查)
      if (pattern.endsWith('|') && !pattern.endsWith(r'\|')) {
        return false;
      }
    }
    return true;
  }

  int getValidTimeoutMillisecond() {
    return timeoutMillisecond <= 0 ? 3000 : timeoutMillisecond;
  }

  String getDisplayNameGroup() {
    return (group == null || group!.isEmpty) ? name : '$name ($group)';
  }

  /// 執行單條規則替換 (用於調試與預覽)
  String apply(String content) {
    if (pattern.isEmpty) return content;
    try {
      if (isRegex) {
        final reg = RegExp(pattern, multiLine: true, dotAll: true);
        return content.replaceAllMapped(reg, (match) {
          // 替換 $0 為整個匹配項，替換 $1...$N 為捕獲組
          return replacement.replaceAllMapped(RegExp(r'\\\$|\$(\d+)'), (m) {
            final hit = m.group(0)!;
            if (hit == r'\$') {
              return r'$';
            } else {
              final groupIndex = int.tryParse(m.group(1)!) ?? 0;
              if (groupIndex == 0) {
                return match.group(0) ?? '';
              }
              if (groupIndex > 0 && groupIndex <= match.groupCount) {
                return match.group(groupIndex) ?? '';
              }
              return hit;
            }
          });
        });
      } else {
        return content.replaceAll(pattern, replacement);
      }
    } catch (_) {
      return content;
    }
  }

  factory ReplaceRule.fromJson(Map<String, dynamic> json) {
    return ReplaceRule(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      group: json['group'],
      pattern: json['pattern'] ?? '',
      replacement: json['replacement'] ?? '',
      scope: json['scope'],
      scopeTitle: json['scopeTitle'] == 1 || json['scopeTitle'] == true,
      scopeContent: json['scopeContent'] == 1 || json['scopeContent'] == true,
      excludeScope: json['excludeScope'],
      isEnabled: json['isEnabled'] == 1 || json['isEnabled'] == true,
      isRegex: json['isRegex'] == 1 || json['isRegex'] == true,
      timeoutMillisecond: json['timeoutMillisecond'] ?? 3000,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id == 0 ? null : id,
      'name': name,
      'group': group,
      'pattern': pattern,
      'replacement': replacement,
      'scope': scope,
      'scopeTitle': scopeTitle ? 1 : 0,
      'scopeContent': scopeContent ? 1 : 0,
      'excludeScope': excludeScope,
      'isEnabled': isEnabled ? 1 : 0,
      'isRegex': isRegex ? 1 : 0,
      'timeoutMillisecond': timeoutMillisecond,
      'order': order,
    };
  }
}

