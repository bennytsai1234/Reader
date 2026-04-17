import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:path_provider/path_provider.dart';

/// App Theme - 主題配置
/// (原 Android help/config/ReadBookConfig.kt) 與 ThemeConfig.kt
class AppTheme {
  // ... (保留原有的色彩與主題定義)
  static const Color primaryColor = Color(0xFF5B7FFF);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color darkBackgroundColor = Color(0xFF0F172A);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1F2937),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      space: 1,
      color: Color(0xFFF3F4F6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E293B),
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF1E293B),
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: const Color(0xFF1E293B),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Color(0xFF1E293B),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      space: 1,
      color: Color(0xFF334155),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  /// 閱讀排版配置清單 (原 Android configList)
  static List<ReadingTheme> readingThemes = [];

  /// 初始化排版配置 (對標 initConfigs)
  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final configFile = File('${directory.path}/readConfig.json');

    if (await configFile.exists()) {
      try {
        final jsonStr = await configFile.readAsString();
        final List<dynamic> list = jsonDecode(jsonStr);
        readingThemes = list.map((e) => ReadingTheme.fromJson(e)).toList();
      } catch (e) {
        AppLog.e('Error loading reading configs from file: $e', error: e);
      }
    }

    if (readingThemes.isEmpty) {
      await _loadDefaultConfigs();
    }
  }

  static Future<void> _loadDefaultConfigs() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/readConfig.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      readingThemes = list.map((e) => ReadingTheme.fromJson(e)).toList();
    } catch (e) {
      // 最終回退硬編碼配置
      readingThemes = _fallbackThemes;
    }
  }

  static final List<ReadingTheme> _fallbackThemes = [
    ReadingTheme(name: '簡約白', backgroundColor: const Color(0xFFFFFFFF), textColor: const Color(0xFF1A1A1A), lineSpacing: 1.6),
    ReadingTheme(name: '羊皮紙', backgroundColor: const Color(0xFFF4F1E8), textColor: const Color(0xFF244739), lineSpacing: 1.65, paragraphSpacing: 1.2),
    ReadingTheme(name: '嫩草綠', backgroundColor: const Color(0xFFE3EDCD), textColor: const Color(0xFF2D4A32), lineSpacing: 1.6),
    ReadingTheme(name: '雅緻褐', backgroundColor: const Color(0xFFD8C8A8), textColor: const Color(0xFF3E2723), lineSpacing: 1.6),
    ReadingTheme(name: '深海藍', backgroundColor: const Color(0xFF0F1D19), textColor: const Color(0xFFB9D7C2), lineSpacing: 1.6),
    ReadingTheme(name: '夜間', backgroundColor: const Color(0xFF1A1A1A), textColor: const Color(0xFF999999), lineSpacing: 1.6),
    ReadingTheme(name: '極黑', backgroundColor: const Color(0xFF000000), textColor: const Color(0xFF777777), lineSpacing: 1.6),
  ];
}

/// ReadingTheme - 閱讀排版配置模型
/// (原 Android ReadBookConfig.Config) 類別
class ReadingTheme {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  
  // 核心排版屬性 (原 Android Config 屬性)
  final double textSize;
  final double lineSpacing;
  final double paragraphSpacing;
  final double letterSpacing;
  final String paragraphIndent;
  final EdgeInsets padding;
  final int titleMode; // 0:左, 1:中, 2:隱藏
  final double titleSize;
  final String? fontFamily;
  String? backgroundImage;

  ReadingTheme({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    this.textSize = 18.0,
    this.lineSpacing = 1.5,
    this.paragraphSpacing = 1.0,
    this.letterSpacing = 0.0,
    this.paragraphIndent = '　　',
    this.padding = const EdgeInsets.all(16.0),
    this.titleMode = 1,
    this.titleSize = 22.0,
    this.fontFamily,
    this.backgroundImage,
  });

  factory ReadingTheme.fromJson(Map<String, dynamic> json) {
    int parseColor(dynamic v, String def) {
      if (v == null) return int.parse(def);
      if (v is int) return v;
      if (v is String) {
        if (v.startsWith('0x')) return int.parse(v);
        if (v.startsWith('#')) return int.parse('0xFF${v.substring(1)}');
        return int.tryParse(v) ?? int.parse(def);
      }
      return int.parse(def);
    }

    double parseDouble(dynamic v, double def) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? def;
      return def;
    }

    return ReadingTheme(
      name: json['name'] ?? '未命名',
      backgroundColor: Color(parseColor(json['backgroundColor'], '0xFFFFFFFF')),
      textColor: Color(parseColor(json['textColor'], '0xFF1A1A1A')),
      textSize: parseDouble(json['textSize'], 18.0),
      lineSpacing: parseDouble(json['lineSpacing'], 1.5),
      paragraphSpacing: parseDouble(json['paragraphSpacing'], 1.0),
      letterSpacing: parseDouble(json['letterSpacing'], 0.0),
      paragraphIndent: json['paragraphIndent'] ?? '　　',
      padding: EdgeInsets.fromLTRB(
        parseDouble(json['paddingLeft'], 16.0),
        parseDouble(json['paddingTop'], 16.0),
        parseDouble(json['paddingRight'], 16.0),
        parseDouble(json['paddingBottom'], 16.0),
      ),
      titleMode: json['titleMode'] ?? 1,
      titleSize: parseDouble(json['titleSize'], 22.0),
      fontFamily: json['fontFamily'],
      backgroundImage: json['backgroundImage'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'backgroundColor': '0x${backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
    'textColor': '0x${textColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
    'textSize': textSize,
    'lineSpacing': lineSpacing,
    'paragraphSpacing': paragraphSpacing,
    'letterSpacing': letterSpacing,
    'paragraphIndent': paragraphIndent,
    'paddingLeft': padding.left,
    'paddingTop': padding.top,
    'paddingRight': padding.right,
    'paddingBottom': padding.bottom,
    'titleMode': titleMode,
    'titleSize': titleSize,
    'fontFamily': fontFamily,
    'backgroundImage': backgroundImage,
  };
}

