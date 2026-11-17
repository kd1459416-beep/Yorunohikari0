import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/inset_section.dart';

class _News {
  const _News(this.title, this.body, this.date);
  final String title, body;
  final DateTime? date;

  static _News? tryParse(Map<String, dynamic> m) {
    final title = m['title'] as String?;
    if (title == null) return null;
    return _News(
      title,
      m['body'] as String? ?? '',
      (m['date'] as Timestamp?)?.toDate(),
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final Stream<List<_News>> _stream = FirebaseFirestore.instance
      .collection('announcements')
      .orderBy('date', descending: true)
      .limit(30)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => _News.tryParse(d.data())).nonNulls.toList(),
      );

  void _show(_News n) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(n.title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(n.body.isEmpty ? '（本文はありません）' : n.body),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('お知らせ')),
      body: StreamBuilder<List<_News>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('お知らせ取得エラー: ${snapshot.error}');
            return Center(
              child: Text(
                '読み込めませんでした',
                style: TextStyle(color: p.textSecondary),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return Center(
              child: Text(
                'お知らせはありません',
                style: TextStyle(color: p.textSecondary),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(top: 16),
            children: [
              InsetSection(
                children: [
                  for (final n in list)
                    InsetTile(
                      title: n.title,
                      value: n.date == null
                          ? null
                          : '${n.date!.month}/${n.date!.day}',
                      onTap: () => _show(n),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
