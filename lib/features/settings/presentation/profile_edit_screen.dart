import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/inset_section.dart';
import '../../../core/widgets/labeled_segmented.dart';
import '../data/user_repository.dart';

enum BabyGender {
  boy('男の子'),
  girl('女の子'),
  unset('未設定');

  const BabyGender(this.label);
  final String label;

  static BabyGender parse(Object? v) => values.asNameMap()[v] ?? unset;
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const _weightMin = 200; // g
  static const _weightMax = 6500; // g

  final _repo = UserRepository();
  final _babyName = TextEditingController();
  final _weight = TextEditingController();
  final _nickname = TextEditingController();
  BabyGender _gender = BabyGender.unset;
  DateTime? _birthDate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await _repo.load();
    if (!mounted) return;
    setState(() {
      _babyName.text = d['babyName'] as String? ?? '';
      _nickname.text = d['nickname'] as String? ?? '';
      _birthDate = (d['childBirthDate'] as Timestamp?)?.toDate();
      _gender = BabyGender.parse(d['babyGender']);
      final w = d['birthWeightG'] as num?;
      _weight.text = w == null ? '' : '${w.toInt()}';
    });
  }

  @override
  void dispose() {
    _babyName.dispose();
    _weight.dispose();
    _nickname.dispose();
    super.dispose();
  }

  int? get _ageInMonths {
    final b = _birthDate;
    if (b == null) return null;
    final n = DateTime.now();
    return (n.year - b.year) * 12 + n.month - b.month - (n.day < b.day ? 1 : 0);
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final p = AppPalette.of(context);
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => ColoredBox(
        color: p.surface,
        child: SizedBox(
          height: 260,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _birthDate ?? DateTime.now(),
            maximumDate: DateTime.now(),
            onDateTimeChanged: (d) => setState(() => _birthDate = d),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final text = _weight.text.trim();
    final weight = text.isEmpty ? null : int.tryParse(text);
    if (weight != null && (weight < _weightMin || weight > _weightMax)) {
      setState(() => _error = '出生体重は$_weightMin〜${_weightMax}gの範囲で入力してください');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.update({
        'nickname': _nickname.text.trim(),
        'babyName': _babyName.text.trim(),
        'childBirthDate': _birthDate == null
            ? null
            : Timestamp.fromDate(_birthDate!),
        'babyGender': _gender.name,
        'birthWeightG': weight,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('プロフィール保存エラー: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存できませんでした。通信を確認して、もう一度お試しください。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final b = _birthDate;
    final months = _ageInMonths;
    final caption = TextStyle(fontSize: 13, color: p.textSecondary);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          CupertinoButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          InsetSection(
            header: 'お子さま',
            children: [
              _FieldRow(
                label: '名前',
                child: _textField(
                  p,
                  controller: _babyName,
                  placeholder: '未設定',
                  maxLength: 20,
                ),
              ),
              InsetTile(
                title: '生年月日',
                value: b == null ? '未設定' : '${b.year}年${b.month}月${b.day}日',
                onTap: _pickDate,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: LabeledSegmented<BabyGender>(
                  value: _gender,
                  options: {for (final g in BabyGender.values) g: g.label},
                  onChanged: (g) => setState(() => _gender = g),
                ),
              ),
              _FieldRow(
                label: '出生体重',
                child: CupertinoTextField(
                  controller: _weight,
                  decoration: null, // 枠線なし
                  textAlign: TextAlign.end,
                  placeholder: '未設定',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  suffix: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'g',
                      style: TextStyle(fontSize: 16, color: p.textSecondary),
                    ),
                  ),
                  style: TextStyle(color: p.textPrimary),
                  placeholderStyle: TextStyle(color: p.textSecondary),
                ),
              ),
            ],
          ),
          if (months != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
              child: Text('月齢 ${months}か月', style: caption),
            ),
          InsetSection(
            header: 'あなた',
            children: [
              _FieldRow(
                label: 'ニックネーム',
                child: _textField(
                  p,
                  controller: _nickname,
                  placeholder: '未設定',
                  maxLength: 20,
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemRed,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _textField(
    AppPalette p, {
    required TextEditingController controller,
    required String placeholder,
    int? maxLength,
  }) {
    return CupertinoTextField(
      controller: controller,
      decoration: null, // 枠線なし
      textAlign: TextAlign.end,
      placeholder: placeholder,
      maxLength: maxLength,
      style: TextStyle(color: p.textPrimary),
      placeholderStyle: TextStyle(color: p.textSecondary),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: p.textPrimary),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
