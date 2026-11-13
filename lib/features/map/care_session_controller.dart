import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'data/presence_repository.dart';
import '../records/data/record_repository.dart';
import '../records/domain/care_record.dart';

enum CareStatus {
  none,
  nursing,
  sleeping;

  RecordType? get recordType => switch (this) {
    none => null,
    nursing => RecordType.nursing,
    sleeping => RecordType.sleep,
  };
}

class CareSessionController extends ChangeNotifier {
  CareSessionController({
    PresenceRepository? presence,
    RecordRepository? records,
  }) : _presence = presence ?? PresenceRepository(),
       _records = records ?? RecordRepository();

  final PresenceRepository _presence;
  final RecordRepository _records;

  /// 毎秒更新。画面全体を再構築しないよう別Notifierにしている。
  final elapsed = ValueNotifier(Duration.zero);

  CareStatus _status = CareStatus.none;
  CareStatus get status => _status;
  Timer? _ticker;

  void start(CareStatus status) {
    _ticker?.cancel();
    elapsed.value = Duration.zero;
    _setStatus(status);
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => elapsed.value += const Duration(seconds: 1),
    );
  }

  void cancel() => _stop();

  Future<void> finish(String detail) async {
    final type = _status.recordType;
    final duration = elapsed.value;
    _stop(); // 先に状態を戻すので二重保存フラグは不要
    if (type == null || duration == Duration.zero) return;
    await _records.add(
      CareRecord(
        type: type,
        endedAt: DateTime.now(),
        duration: duration,
        detail: detail,
      ),
    );
  }

  void _stop() {
    _ticker?.cancel();
    elapsed.value = Duration.zero;
    _setStatus(CareStatus.none);
  }

  void _setStatus(CareStatus status) {
    _status = status;
    notifyListeners();
    _presence.setStatus(status.name);

    // _presence.update({
    // 'status': status.name,
    // 'statusUpdatedAt': FieldValue.serverTimestamp(),
    // });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    elapsed.dispose();
    super.dispose();
  }
}
