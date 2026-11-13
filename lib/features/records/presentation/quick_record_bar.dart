import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_palette.dart';
import '../domain/care_record.dart';
import 'record_type_style.dart';

/// 記録画面の上部に常に出す、ワンタップ記録のボタン。
/// 「授乳」「寝かしつけ」「おしっこ」「うんち」と、右端の「＋その他」。
class QuickRecordBar extends StatelessWidget {
  const QuickRecordBar({
    super.key,
    required this.onRecord,
    required this.onMore,
  });

  final ValueChanged<RecordType> onRecord;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SizedBox(
        height: 88,
        child: Row(
          children: [
            for (final type in RecordType.mainTypes) ...[
              Expanded(
                child: _QuickButton(type: type, onTap: () => onRecord(type)),
              ),
              const SizedBox(width: 8),
            ],
            _MoreButton(onTap: onMore),
          ],
        ),
      ),
    );
  }
}

/// 押している間だけ少し縮む、大きなボタン
class _QuickButton extends StatefulWidget {
  const _QuickButton({required this.type, required this.onTap});

  final RecordType type;
  final VoidCallback onTap;

  @override
  State<_QuickButton> createState() => _QuickButtonState();
}

class _QuickButtonState extends State<_QuickButton> {
  bool _isPressed = false;

  void _setPressed(bool value) => setState(() => _isPressed = value);

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = widget.type.color(p);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 80),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.type.icon(color, size: 30),
              const SizedBox(height: 8),
              // 「寝かしつけ」のような長い名前でも、はみ出さないように縮める
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.type.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「＋その他」。メインより控えめな見た目
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.plus, size: 24, color: p.textSecondary),
              const SizedBox(height: 8),
              Text(
                'その他',
                style: TextStyle(fontSize: 11, color: p.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
