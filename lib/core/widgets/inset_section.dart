import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// 背景色の差だけでまとまりを示すセクション。Borderは使わない。
class InsetSection extends StatelessWidget {
  const InsetSection({
    super.key,
    this.header,
    required this.children,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  final String? header;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                header!,
                style: TextStyle(fontSize: 13, color: p.textSecondary),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: p.surface,
              child: Column(
                children: [
                  for (final (i, child) in children.indexed) ...[
                    if (i > 0) const Divider(indent: 16),
                    child,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InsetTile extends StatelessWidget {
  const InsetTile({
    super.key,
    required this.title,
    this.value,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: destructive
                      ? CupertinoColors.systemRed
                      : p.textPrimary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: TextStyle(fontSize: 15, color: p.textSecondary),
              ),
            if (trailing != null)
              trailing!
            else if (onTap != null && !destructive)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  size: 15,
                  color: p.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
