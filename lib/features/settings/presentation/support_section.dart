import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/widgets/inset_section.dart';
import 'news_screen.dart';

class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return InsetSection(
      header: 'サポート',
      children: [
        InsetTile(
          title: 'お知らせ',
          onTap: () => Navigator.of(
            context,
          ).push(CupertinoPageRoute<void>(builder: (_) => const NewsScreen())),
        ),
        InsetTile(title: 'お問い合わせ', onTap: () => _contact(context)),
        InsetTile(title: 'アプリをレビューする', onTap: () => _review(context)),
        InsetTile(title: 'アプリを共有する', onTap: _share),
        InsetTile(title: '利用規約', onTap: () => _terms(context)),
      ],
    );
  }
}

Future<bool> _open(
  Uri uri, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  try {
    return await launchUrl(uri, mode: mode);
  } catch (e) {
    debugPrint('起動エラー: $e');
    return false;
  }
}

Future<void> _notice(
  BuildContext context,
  String message, {
  List<Widget> extra = const [],
}) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message),
      ),
      actions: [
        ...extra,
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}

// メールの件名・本文は、空白を「+」ではなく「%20」にする必要がある
String _query(Map<String, String> p) => p.entries
    .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
    .join('&');

Future<void> _contact(BuildContext context) async {
  final uri = Uri(
    scheme: 'mailto',
    path: AppLinks.contactEmail,
    query: _query({'subject': 'ヨルノヒカリ お問い合わせ', 'body': 'ご用件をご記入ください。\n\n'}),
  );
  if (await _open(uri) || !context.mounted) return;

  // メールアプリがない場合（シミュレーターなど）は、宛先を見せてコピーできるようにする
  await _notice(
    context,
    'メールアプリを開けませんでした。次のアドレスへご連絡ください。\n\n${AppLinks.contactEmail}',
    extra: [
      CupertinoDialogAction(
        onPressed: () =>
            Clipboard.setData(const ClipboardData(text: AppLinks.contactEmail)),
        child: const Text('アドレスをコピー'),
      ),
    ],
  );
}

Future<void> _review(BuildContext context) async {
  final uri = AppLinks.reviewUri;
  if (uri == null) {
    await _notice(context, 'レビューのページは、アプリの公開後に開けるようになります。');
    return;
  }
  await _open(uri);
}

Future<void> _share() => SharePlus.instance.share(
  ShareParams(text: AppLinks.shareText, subject: 'ヨルノヒカリ'),
);

Future<void> _terms(BuildContext context) async {
  // アプリ内でWebページを開く（iOSでは Safari のシートが出る）
  final ok = await _open(
    Uri.parse(AppLinks.termsUrl),
    mode: LaunchMode.inAppBrowserView,
  );
  if (!ok && context.mounted) await _notice(context, '利用規約のページを開けませんでした。');
}
