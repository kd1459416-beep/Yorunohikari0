import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post.dart';

/// 広場の投稿・コメントの読み書きだけを担当する。画面の状態は持たない。
class PlazaRepository {
  PlazaRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const maxPostLength = 300;
  static const maxCommentLength = 200;
  static const _feedLimit = 50;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  /// 新しい順のタイムライン。[category] を指定すると、そのカテゴリだけ
  /// （カテゴリ + 日時の並び替えには、複合インデックスが必要）
  Stream<List<Post>> watchPosts({PostCategory? category}) {
    Query<Map<String, dynamic>> query = _posts;
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(_feedLimit)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => Post.tryParse(d.id, d.data()))
              .nonNulls
              .toList(),
        );
  }

  Future<void> addPost({
    required String text,
    required PostCategory category,
  }) async {
    final id = uid;
    if (id == null) return;
    await _posts.add({
      'text': text,
      'category': category.name,
      'authorId': id,
      'createdAt': FieldValue.serverTimestamp(),
      'commentCount': 0,
    });
  }

  /// 投稿とコメントを、まとめて削除する
  Future<void> deletePost(Post post) async {
    final ref = _posts.doc(post.id);
    final comments = await ref.collection('comments').limit(400).get();
    final batch = _db.batch();
    for (final comment in comments.docs) {
      batch.delete(comment.reference);
    }
    batch.delete(ref);
    await batch.commit();
  }

  /// 古い順（会話の流れが上から読める）
  Stream<List<PostComment>> watchComments(String postId) => _posts
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt')
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => PostComment.tryParse(d.id, d.data()))
            .nonNulls
            .toList(),
      );

  /// コメントの追加と、投稿のコメント数 +1 を、同時に行う
  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final id = uid;
    if (id == null) return;
    final postRef = _posts.doc(postId);
    final batch = _db.batch();
    batch.set(postRef.collection('comments').doc(), {
      'text': text,
      'authorId': id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }
}
