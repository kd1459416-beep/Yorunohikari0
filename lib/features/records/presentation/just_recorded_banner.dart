import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/time_format.dart';
import '../domain/care_record.dart';
import '../quick_record_controller.dart';
import 'record_type_style.dart';

/// ワンタップで記録した直後に、約8秒だけ出るお知らせ。
/// 「詳細」で硬さ・量などを足せる。「取消」で記録を消せる。
class JustRecordedBanner extends StatelessWidget {
  const JustRecordedBanner({
    super.key,
    required this.controller,
    required this.onEditDetail,
  });

  final QuickRecordController controller;
  final ValueChanged<CareRecord> onEditDetail;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final record = controller.last;
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: record == null
              ? const SizedBox(width: double.infinity) // 高さ0 = 非表示
              : _BannerCard(
                  record: record,
                  onEditDetail: () => onEditDetail(record),
                  onUndo: controller.undo,
                ),
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.record,
    required this.onEditDetail,
    required this.onUndo,
  });

  final CareRecord record;
  final VoidCallback onEditDetail;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
          child: Row(
            children: [
              record.type.icon(record.type.color(p), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${record.type.label}を記録しました  ${hm(record.endedAt)}',
                  style: TextStyle(fontSize: 14, color: p.textPrimary),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onPressed: onEditDetail,
                child: const Text('詳細', style: TextStyle(fontSize: 14)),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onPressed: onUndo,
                child: Text(
                  '取消',
                  style: TextStyle(fontSize: 14, color: p.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
