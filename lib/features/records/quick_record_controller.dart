import 'dart:async';
import 'package:flutter/foundation.dart';
import 'data/record_repository.dart';
import 'domain/care_record.dart';

/// ワンタップ記録の状態を持つ。
/// 直前に保存した記録を一定時間だけ覚えておき、「詳細を足す」「取り消す」を可能にする。
class QuickRecordController extends ChangeNotifier {
  QuickRecordController(this._repository);

  static const _bannerDuration = Duration(seconds: 8);

  final RecordRepository _repository;
  CareRecord? _last;
  Timer? _hideTimer;

  /// 直前に保存した記録（なければ null）。この間だけバナーを出す
  CareRecord? get last => _last;

  /// 「いま」の記録を1回で保存する
  Future<void> record(RecordType type) async {
    final now = DateTime.now();
    final id = await _repository.add(CareRecord(type: type, endedAt: now));
    if (id == null) return;

    _last = CareRecord(id: id, type: type, endedAt: now);
    _hideTimer?.cancel();
    _hideTimer = Timer(_bannerDuration, dismiss);
    notifyListeners();
  }

  /// 直前の記録を取り消す
  Future<void> undo() async {
    final id = _last?.id;
    dismiss();
    if (id == null) return;
    try {
      await _repository.delete(id);
    } catch (e) {
      debugPrint('記録の取り消しエラー: $e');
    }
  }

  /// バナーだけを閉じる（記録は残す）
  void dismiss() {
    _hideTimer?.cancel();
    if (_last == null) return;
    _last = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}
