class SourceSubscription {
  int? id;
  
  String name = '';
  String url = '';
  int type = 0; // 0: 書源, 1: RSS, 2: 替換規則
  int customOrder = 0;
  bool autoUpdate = false;
  int lastUpdateTime = 0;

  SourceSubscription({
    this.name = '',
    this.url = '',
    this.type = 0,
    this.customOrder = 0,
    this.autoUpdate = false,
    this.lastUpdateTime = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'type': type,
    'customOrder': customOrder,
    'autoUpdate': autoUpdate,
    'lastUpdateTime': lastUpdateTime,
  };

  factory SourceSubscription.fromJson(Map<String, dynamic> json) {
    return SourceSubscription(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? 0,
      customOrder: json['customOrder'] ?? 0,
      autoUpdate: json['autoUpdate'] ?? false,
      lastUpdateTime: json['lastUpdateTime'] ?? 0,
    );
  }
}
