import 'package:flutter/widgets.dart';
import '../../map/presentation/nursing_detail_sheet.dart';
import '../data/record_repository.dart';
import '../domain/care_record.dart';
import '../domain/record_spec.dart';
import 'record_detail_sheet.dart';

/// 保存済みの記録に、詳細（硬さ・量・メモなど）を足す・変える。
/// 種別に合った入力画面を出して、保存まで行う。
/// （授乳は、これまでの専用シート。それ以外は、種別ごとの入力画面）
Future<void> editRecordDetail(
  BuildContext context,
  RecordRepository repository,
  CareRecord record,
) async {
  final id = record.id;
  if (id == null) return;

  if (record.type == RecordType.nursing) {
    final detail = await showNursingDetailSheet(context);
    if (detail != null) await repository.updateFields(id, {'detail': detail});
    return;
  }

  final input = await showRecordDetailSheet(
    context,
    type: record.type,
    initial: RecordDetail.fromRecord(record),
  );
  if (input != null)
    await repository.updateFields(id, input.toFields(record.type));
}
