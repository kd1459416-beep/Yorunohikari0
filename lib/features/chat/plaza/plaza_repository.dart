import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ng_word_filter.dart';
import 'post.dart';

/// 暴言・連絡先交換などのNGワードを含むときの例外
class PlazaNgContentException implements Exception {
  const PlazaNgContentException();
}

/// 広場の投稿・コメントの読み書きだけを担当する。画面の状態は持たない。
class PlazaRepository {
  PlazaRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const maxPostLength = 300;
  static const maxCommentLength = 200;
  static const _feedLimit = 100;

  /// この人数以上から通報されたら、運営の確認を待たず自動で非表示にする
  static const reportThreshold = 3;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  /// 新しい順のタイムライン。カテゴリでの絞り込みは、画面側で行う
  /// （サーバー側で絞ると複合インデックスが必要で、未作成だと読み込めないため）。
  /// 通報されて非表示になった投稿は、ここで取り除く。
  Stream<List<Post>> watchPosts() => _posts
      .orderBy('createdAt', descending: true)
      .limit(_feedLimit)
      .snapshots()
      .map(
        (s) => s.docs
            .where((d) => d.data()['hidden'] != true)
            .map((d) => Post.tryParse(d.id, d.data()))
            .nonNulls
            .toList(),
      );

  Future<void> addPost({
    required String text,
    required PostCategory category,
  }) async {
    final id = uid;
    if (id == null) return;
    if (containsNgContent(text)) throw const PlazaNgContentException();

    await _posts.add({
      'text': text,
      'category': category.name,
      'authorId': id,
      'createdAt': FieldValue.serverTimestamp(),
      'commentCount': 0,
    });
  }

  /// 投稿を通報する。同じ人からの二重通報はカウントしない。
  /// [reportThreshold] 人に達したら自動で非表示にする。
  Future<void> reportPost(String postId) => _report(_posts.doc(postId));

  /// コメントを通報する（仕組みは投稿と同じ）
  Future<void> reportComment({
    required String postId,
    required String commentId,
  }) => _report(_posts.doc(postId).collection('comments').doc(commentId));

  Future<void> _report(DocumentReference<Map<String, dynamic>> ref) async {
    final id = uid;
    if (id == null) return;
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final reportedBy = List<String>.from(
        (snapshot.data()?['reportedBy'] as List?) ?? const [],
      );
      if (reportedBy.contains(id)) return; // 二重通報はカウントしない
      reportedBy.add(id);
      tx.update(ref, {
        'reportedBy': reportedBy,
        'hidden': reportedBy.length >= reportThreshold,
      });
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

  /// 古い順（会話の流れが上から読める）。通報されて非表示になったコメントは除く。
  Stream<List<PostComment>> watchComments(String postId) => _posts
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt')
      .snapshots()
      .map(
        (s) => s.docs
            .where((d) => d.data()['hidden'] != true)
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
    if (containsNgContent(text)) throw const PlazaNgContentException();

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
