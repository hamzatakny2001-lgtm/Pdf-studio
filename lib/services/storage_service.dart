import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentFile {
  final String path;
  final String name;
  final DateTime createdAt;
  final int pageCount;
  final int fileSizeBytes;

  const RecentFile({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.pageCount,
    required this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'pageCount': pageCount,
        'fileSizeBytes': fileSizeBytes,
      };

  factory RecentFile.fromJson(Map<String, dynamic> json) => RecentFile(
        path: json['path'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        pageCount: json['pageCount'] as int? ?? 0,
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      );
}

class StorageService {
  static const _key = 'recent_files';
  static const _maxRecents = 20;

  static Future<List<RecentFile>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => RecentFile.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> addRecentFile(RecentFile file) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getRecentFiles();
    current.removeWhere((f) => f.path == file.path);
    current.insert(0, file);
    final trimmed = current.take(_maxRecents).toList();
    await prefs.setStringList(
        _key, trimmed.map((f) => jsonEncode(f.toJson())).toList());
  }

  static Future<void> removeRecentFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getRecentFiles();
    current.removeWhere((f) => f.path == path);
    await prefs.setStringList(
        _key, current.map((f) => jsonEncode(f.toJson())).toList());
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
