import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 投稿のカテゴリ。Firestore には `name`（nursing など）を保存する。
enum PostCategory {
  nursing('授乳中'),
  sleeping('寝かしつけ中'),
  chatting('雑談'),
  weaning('離乳食'),
  pregnancy('妊娠出産'),
  checkup('健診');

  const PostCategory(this.label);
  final String label;

  static PostCategory parse(Object? value) =>
      values.asNameMap()[value] ?? chatting;
}

/// タイムラインの1投稿
class Post {
  const Post({
    required this.id,
    required this.text,
    required this.category,
    required this.authorId,
    required this.createdAt,
    required this.commentCount,
  });

  final String id;
  final String text;
  final PostCategory category;
  final String authorId;
  final DateTime createdAt;
  final int commentCount;

  static Post? tryParse(String id, Map<String, dynamic> data) {
    final text = data['text'] as String?;
    if (text == null) return null;
    return Post(
      id: id,
      text: text,
      category: PostCategory.parse(data['category']),
      authorId: data['authorId'] as String? ?? '',
      // サーバー時刻が確定する前は null。その間は「今」として扱う
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 投稿へのコメント
class PostComment {
  const PostComment({
    required this.id,
    required this.text,
    required this.authorId,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String authorId;
  final DateTime createdAt;

  static PostComment? tryParse(String id, Map<String, dynamic> data) {
    final text = data['text'] as String?;
    if (text == null) return null;
    return PostComment(
      id: id,
      text: text,
      authorId: data['authorId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// 完全匿名。IDの先頭4文字だけを目印にする
String anonymousName(String authorId) =>
    '匿名 ${authorId.substring(0, min(4, authorId.length))}';
