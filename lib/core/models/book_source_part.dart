/// BookSourcePart - 書源局部模型 (用於列表顯示或局部更新)
/// (原 Android data/entities/BookSourcePart.kt)
class BookSourcePart {
  String bookSourceUrl;
  String bookSourceName;
  String? bookSourceGroup;
  int customOrder;
  bool enabled;
  bool enabledExplore;
  bool hasLoginUrl;
  bool hasExploreUrl;
  bool hasSearchUrl;
  bool hasBookInfoRule;
  bool hasTocRule;
  bool hasContentRule;
  int lastUpdateTime;
  int respondTime;
  int weight;

  BookSourcePart({
    this.bookSourceUrl = '',
    this.bookSourceName = '',
    this.bookSourceGroup,
    this.customOrder = 0,
    this.enabled = true,
    this.enabledExplore = true,
    this.hasLoginUrl = false,
    this.hasExploreUrl = false,
    this.hasSearchUrl = false,
    this.hasBookInfoRule = false,
    this.hasTocRule = false,
    this.hasContentRule = false,
    this.lastUpdateTime = 0,
    this.respondTime = 180000,
    this.weight = 0,
  });

  String getDisplayNameGroup() {
    if (bookSourceGroup == null || bookSourceGroup!.isEmpty) {
      return bookSourceName;
    } else {
      return '$bookSourceName ($bookSourceGroup)';
    }
  }

  factory BookSourcePart.fromJson(Map<String, dynamic> json) {
    return BookSourcePart(
      bookSourceUrl: json['bookSourceUrl'] ?? '',
      bookSourceName: json['bookSourceName'] ?? '',
      bookSourceGroup: json['bookSourceGroup'],
      customOrder: json['customOrder'] ?? 0,
      enabled: json['enabled'] == 1 || json['enabled'] == true,
      enabledExplore: json['enabledExplore'] == 1 || json['enabledExplore'] == true,
      hasLoginUrl: json['hasLoginUrl'] == 1 || json['hasLoginUrl'] == true,
      hasExploreUrl: json['hasExploreUrl'] == 1 || json['hasExploreUrl'] == true,
      hasSearchUrl: json['hasSearchUrl'] == 1 || json['hasSearchUrl'] == true,
      hasBookInfoRule: json['hasBookInfoRule'] == 1 || json['hasBookInfoRule'] == true,
      hasTocRule: json['hasTocRule'] == 1 || json['hasTocRule'] == true,
      hasContentRule: json['hasContentRule'] == 1 || json['hasContentRule'] == true,
      lastUpdateTime: json['lastUpdateTime'] ?? 0,
      respondTime: json['respondTime'] ?? 180000,
      weight: json['weight'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookSourceUrl': bookSourceUrl,
      'bookSourceName': bookSourceName,
      'bookSourceGroup': bookSourceGroup,
      'customOrder': customOrder,
      'enabled': enabled ? 1 : 0,
      'enabledExplore': enabledExplore ? 1 : 0,
      'hasLoginUrl': hasLoginUrl ? 1 : 0,
      'hasExploreUrl': hasExploreUrl ? 1 : 0,
      'hasSearchUrl': hasSearchUrl ? 1 : 0,
      'hasBookInfoRule': hasBookInfoRule ? 1 : 0,
      'hasTocRule': hasTocRule ? 1 : 0,
      'hasContentRule': hasContentRule ? 1 : 0,
      'lastUpdateTime': lastUpdateTime,
      'respondTime': respondTime,
      'weight': weight,
    };
  }
}

