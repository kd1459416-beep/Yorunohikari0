import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/care_icons.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../care_session_controller.dart';
import 'nursing_detail_sheet.dart';

class CareControls extends StatelessWidget {
  const CareControls({super.key, required this.session});

  final CareSessionController session;

  Future<void> _cancel(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      message: '取り消してもよろしいですか？',
      destructive: true,
    );
    if (ok) session.cancel();
  }

  Future<void> _finish(BuildContext context) async {
    if (session.status == CareStatus.nursing) {
      // 授乳は詳細入力のシートが確認を兼ねる。閉じたら計測を続ける
      final detail = await showNursingDetailSheet(context);
      if (detail == null) return;
      await session.finish(detail);
    } else {
      final ok = await confirmDialog(context, message: '本当に寝かしつけを終了しますか？');
      if (!ok) return;
      await session.finish('完了');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final status = session.status;
        final isNursing = status == CareStatus.nursing;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: status != CareStatus.none
              ? Row(
                  children: [
                    CareStatusIcon(
                      isNursing: isNursing,
                      color: isNursing ? p.nursing : p.sleeping,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ValueListenableBuilder<Duration>(
                        valueListenable: session.elapsed,
                        builder: (_, d, _) => Text(
                          '${isNursing ? '授乳' : '寝かしつけ'}  '
                          '${two(d.inMinutes)}:${two(d.inSeconds % 60)}',
                          style: TextStyle(fontSize: 17, color: p.textPrimary),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => _cancel(context),
                      child: const Text('取消'),
                    ),
                    CupertinoButton.filled(
                      onPressed: () => _finish(context),
                      child: const Text('終了'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _StartButton(
                        label: '授乳開始',
                        color: p.nursing,
                        icon: BottleIcon(size: 20, color: p.nursing),
                        onPressed: () => session.start(CareStatus.nursing),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StartButton(
                        label: '寝かしつけ開始',
                        color: p.sleeping,
                        icon: Icon(
                          CupertinoIcons.moon_zzz_fill,
                          size: 20,
                          color: p.sleeping,
                        ),
                        onPressed: () => session.start(CareStatus.sleeping),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.tinted(
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
