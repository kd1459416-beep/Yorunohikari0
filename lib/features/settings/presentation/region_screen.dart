import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/prefectures.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/inset_section.dart';
import '../data/region_service.dart';
import '../data/user_repository.dart';

class RegionScreen extends StatefulWidget {
  const RegionScreen({super.key});

  @override
  State<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends State<RegionScreen> {
  final _users = UserRepository();
  final _region = RegionService();
  final _cityController = TextEditingController();
  String _prefecture = '東京都';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _users.load().then((data) {
      if (!mounted) return;
      setState(() {
        _prefecture = data['prefecture'] as String? ?? _prefecture;
        _cityController.text = data['city'] as String? ?? '';
      });
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final city = _cityController.text.trim();
    final base = await _region.resolve(_prefecture, city);
    final shown = _region.blur(base); // 保存するのはずらした座標のみ
    await _users.update({
      'prefecture': _prefecture,
      'city': city,
      'latitude': shown.latitude,
      'longitude': shown.longitude,
    });
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('地域'),
        actions: [
          CupertinoButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16),
        children: [
          InsetSection(
            header: '市区町村（任意）',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: CupertinoTextField(
                  controller: _cityController,
                  decoration: null,
                  placeholder: '例：渋谷区',
                  style: TextStyle(color: p.textPrimary),
                ),
              ),
            ],
          ),
          InsetSection(
            header: '都道府県',
            children: [
              for (final pref in prefectureCoordinates.keys)
                InsetTile(
                  title: pref,
                  onTap: () => setState(() => _prefecture = pref),
                  trailing: pref == _prefecture
                      ? Icon(
                          CupertinoIcons.checkmark,
                          size: 18,
                          color: p.accent,
                        )
                      : const SizedBox(width: 18),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '地図には、実際の位置から少しずらした場所が表示されます。',
              style: TextStyle(fontSize: 13, color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
