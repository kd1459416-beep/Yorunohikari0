import 'package:flutter/material.dart';
import '../../../core/widgets/inset_section.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const _sections = <String, List<String>>{
    '音源・効果音': ['OtoLogic', 'VSQ plus+', '効果音ラボ', 'FREE BGM'],
    '地図': [
      '© OpenStreetMap contributors',
      'Tiles © Esri — Source: Esri, DeLorme, NAVTEQ',
    ],
    'AI': ['Gemini API'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('クレジット表記')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16),
        children: [
          for (final MapEntry(:key, :value) in _sections.entries)
            InsetSection(
              header: key,
              children: [for (final name in value) InsetTile(title: name)],
            ),
          InsetSection(
            children: [
              InsetTile(
                title: 'オープンソースライセンス',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'ヨルノヒカリ',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
