import 'dart:convert';
import 'package:flutter/services.dart';

// 1. SoundItem モデル
class SoundItem {
  final String id;
  final String title;
  final String category;
  final String assetPath;

  SoundItem({
    required this.id,
    required this.title,
    required this.category,
    required this.assetPath,
  });
}

// 2. loadSounds 関数
Future<List<SoundItem>> loadSounds() async {
  final String response = await rootBundle.loadString(
    'assets/json/sounds.json',
  );
  final List<dynamic> data = json.decode(response);

  return data
      .map(
        (json) => SoundItem(
          id: json['id'],
          title: json['title'],
          category: json['category'],
          assetPath: 'bgm/${json['file']}',
        ),
      )
      .toList();
}
