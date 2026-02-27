// SI010_2.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const _Si010RunnerApp());
}

class _Si010RunnerApp extends StatelessWidget {
  const _Si010RunnerApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '旅リアン',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      home: const Si010_2Page(),
    );
  }
}

class Si010_2Page extends StatefulWidget {
  const Si010_2Page({super.key});

  @override
  State<Si010_2Page> createState() => _Si010_2PageState();
}

class _Si010_2PageState extends State<Si010_2Page> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ---- Plan basic info ----
  final TextEditingController _planTitle = TextEditingController();
  final TextEditingController _destination = TextEditingController();
  final TextEditingController _stay = TextEditingController();
  final TextEditingController _overviewMemo = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  static const List<String> _transportOptions = <String>[
    '未設定',
    '電車',
    '飛行機',
    'バス',
    '徒歩',
    '車',
    'タクシー',
    '自転車',
    '船',
    'その他',
  ];
  String _transport = '未設定';

  // 公開設定（Phase1は非公開必須）
  bool _isPrivateOnly = true;

  // ---- Schedule ----
  final List<DayDraft> _days = [];

  // ---- UI ----
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  // いつものメニューバー（仮）
  int _menuIndex = 1; // 0=旅行一覧, 1=作成(この画面), 2=スケジュール, 3=設定

  static const List<String> _entryTypeOptions = <String>[
    '集合',
    '移動',
    '到着',
    '観光',
    '食事',
    '宿泊',
    'その他',
  ];

  @override
  void initState() {
    super.initState();

    // どれか触れたら未保存扱い
    _planTitle.addListener(_markDirty);
    _destination.addListener(_markDirty);
    _stay.addListener(_markDirty);
    _overviewMemo.addListener(_markDirty);
  }

  @override
  void dispose() {
    _planTitle.dispose();
    _destination.dispose();
    _stay.dispose();
    _overviewMemo.dispose();
    for (final d in _days) {
      d.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (_hasUnsavedChanges) return;
    setState(() => _hasUnsavedChanges = true);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  String _timeLabel(TimeOfDay? t) {
    if (t == null) return '--:--';
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _requiredLabel(BuildContext context, String text) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final style =
        Theme.of(context).textTheme.labelLarge ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    return RichText(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: onSurface),
        children: const [
          TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  // -----------------------
  // 未保存確認（共通）
  // -----------------------
  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges) return true;

    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('未保存の変更があります'),
          content: const Text('このまま移動すると入力した内容が破棄されます。破棄しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('破棄する'),
            ),
          ],
        );
      },
    );

    return discard ?? false;
  }

  Future<void> _handleBack() async {
    final ok = await _confirmDiscardIfNeeded();
    if (!mounted) return;
    if (ok) Navigator.of(context).maybePop();
  }

  // -----------------------
  // 日程：開始/終了
  // -----------------------
  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: '開始日を選択',
      confirmText: '決定',
      cancelText: 'キャンセル',
    );
    if (!mounted || picked == null) return;

    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked; // 不整合を軽減
      }
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initial = _endDate ?? _startDate ?? now;
    final first = _startDate ?? DateTime(now.year - 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(now.year + 5),
      helpText: '終了日を選択',
      confirmText: '決定',
      cancelText: 'キャンセル',
    );
    if (!mounted || picked == null) return;

    setState(() {
      _endDate = picked;
      _hasUnsavedChanges = true;
    });
  }

  // -----------------------
  // 日付：追加・削除
  // -----------------------
  Future<void> _addDay() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: '日付を選択',
      confirmText: '決定',
      cancelText: 'キャンセル',
    );
    if (!mounted || picked == null) return;

    final exists = _days.any((d) => _isSameDay(d.date, picked));
    if (exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('同じ日付がすでに追加されています')));
      return;
    }

    setState(() {
      _days.add(DayDraft(date: _dateOnly(picked)));
      _days.sort((a, b) => a.date.compareTo(b.date));
      _hasUnsavedChanges = true;
    });
  }

  void _removeDay(int index) {
    setState(() {
      _days[index].dispose();
      _days.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  // -----------------------
  // 予定：追加・編集・削除（シンプル）
  // -----------------------
  int _entrySort(ScheduleEntryDraft a, ScheduleEntryDraft b) {
    final ta = a.time;
    final tb = b.time;
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    final am = ta.hour * 60 + ta.minute;
    final bm = tb.hour * 60 + tb.minute;
    return am.compareTo(bm);
  }

  Future<void> _addEntry(int dayIndex) async {
    final created = await showDialog<ScheduleEntryValue>(
      context: context,
      builder:
          (_) => _AddOrEditEntryDialog(
            typeOptions: _entryTypeOptions,
            transportOptions: _transportOptions,
          ),
    );
    if (!mounted || created == null) return;

    setState(() {
      _days[dayIndex].entries.add(ScheduleEntryDraft.fromValue(created));
      _days[dayIndex].entries.sort(_entrySort);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _editEntry(int dayIndex, int entryIndex) async {
    final entry = _days[dayIndex].entries[entryIndex];

    final edited = await showDialog<ScheduleEntryValue>(
      context: context,
      builder:
          (_) => _AddOrEditEntryDialog(
            typeOptions: _entryTypeOptions,
            transportOptions: _transportOptions,
            initialTime: entry.time,
            initialType: entry.type,
            initialTitle: entry.title.text,
            initialDesc: entry.desc.text,
            initialMemo: entry.memo.text,
            initialTransport: entry.transport,
          ),
    );
    if (!mounted || edited == null) return;

    setState(() {
      entry.time = edited.time;
      entry.type = edited.type;
      entry.transport = edited.transport;
      entry.title.text = edited.title;
      entry.desc.text = edited.desc;
      entry.memo.text = edited.memo;
      _days[dayIndex].entries.sort(_entrySort);
      _hasUnsavedChanges = true;
    });
  }

  void _removeEntry(int dayIndex, int entryIndex) {
    setState(() {
      _days[dayIndex].entries[entryIndex].dispose();
      _days[dayIndex].entries.removeAt(entryIndex);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _confirmAndRemoveEntry(int dayIndex, int entryIndex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('予定を削除'),
            content: const Text('この予定を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除'),
              ),
            ],
          ),
    );
    if (!mounted) return;
    if (ok == true) _removeEntry(dayIndex, entryIndex);
  }

  // -----------------------
  // 保存
  // -----------------------
  bool _isSaveEnabled() {
    final titleOk = _planTitle.text.trim().isNotEmpty;
    final datesOk =
        _startDate != null &&
        _endDate != null &&
        !_endDate!.isBefore(_startDate!);
    return titleOk && datesOk && !_isSaving;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    // Formのvalidator
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    // 追加チェック：日程
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('日程（開始日・終了日）を入力してください')));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('終了日は開始日以降を選択してください')));
      return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final dayCount = _days.length;
    final entryCount = _days.fold<int>(0, (sum, d) => sum + d.entries.length);

    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false; // ✅ 保存したら未保存フラグを落とす
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('保存しました：日付$dayCount件 / 予定$entryCount件')),
    );
  }

  // -----------------------
  // メニュータップ
  // -----------------------
  Future<void> _onTapMenu(int index) async {
    if (index == _menuIndex) return;

    final ok = await _confirmDiscardIfNeeded();
    if (!mounted) return;
    if (!ok) return;

    setState(() => _menuIndex = index);

    const labels = ['旅行一覧', '作成', 'スケジュール', '設定'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「${labels[index]}」は未実装（ここに画面遷移を追加）')),
    );
  }

  // -----------------------
  // util
  // -----------------------
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        Theme.of(context).textTheme.titleMedium ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    final hintStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey) ??
        const TextStyle(color: Colors.grey);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: const CommonLogo(iconSize: 36, fontSize: 16),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
              children: [
                // ---- プラン情報（必須） ----
                _SectionCard(
                  title: 'プラン情報',
                  subtitle: '旅行タイトル／基本情報／概要メモ',
                  titleStyle: titleStyle,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _planTitle,
                        decoration: InputDecoration(
                          label: _requiredLabel(context, '旅行タイトル'),
                          hintText: '例）沖縄 2泊3日',
                          hintStyle: hintStyle,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return '旅行タイトルを入力してください';
                          if (t.length > 50) return '50文字以内で入力してください';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _destination,
                        decoration: InputDecoration(
                          labelText: '目的地',
                          hintText: '例）那覇・本部町',
                          hintStyle: hintStyle,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerField(
                              label: _requiredLabel(context, '開始日'),
                              valueText:
                                  _startDate == null
                                      ? '未設定'
                                      : _fmtDate(_startDate!),
                              onTap: _pickStartDate,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DatePickerField(
                              label: _requiredLabel(context, '終了日'),
                              valueText:
                                  _endDate == null
                                      ? '未設定'
                                      : _fmtDate(_endDate!),
                              onTap: _pickEndDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _stay,
                        decoration: InputDecoration(
                          labelText: '滞在先',
                          hintText: '例）ホテル名／住所など',
                          hintStyle: hintStyle,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: _transport,
                        items:
                            _transportOptions
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          setState(() {
                            _transport = v ?? '未設定';
                            _hasUnsavedChanges = true;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: '移動手段',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _overviewMemo,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'プラン概要メモ',
                          hintText: '旅の概要やメモ（テキスト）',
                          hintStyle: hintStyle,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ---- 公開設定（必須：非公開） ----
                _SectionCard(
                  title: '公開設定',
                  subtitle: 'Phase1は非公開（自分のみ）',
                  titleStyle: titleStyle,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('非公開（自分のみ）'),
                    subtitle: const Text('このプランは自分だけが閲覧できます'),
                    value: _isPrivateOnly,
                    // Phase1は必須にしたいのでOFFは不可（工数削減＆要件担保）
                    onChanged: (v) {
                      if (!v) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Phase1では「非公開」のみ対応します')),
                        );
                        return;
                      }
                      setState(() {
                        _isPrivateOnly = true;
                        _hasUnsavedChanges = true;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // ---- スケジュール ----
                _SectionCard(
                  title: 'スケジュール',
                  subtitle: '日付を追加し、日別に予定を登録します',
                  titleStyle: titleStyle,
                  trailing: FilledButton.tonalIcon(
                    onPressed: _addDay,
                    icon: const Icon(Icons.add),
                    label: const Text('日付を追加'),
                  ),
                  child: Column(
                    children: [
                      if (_days.isEmpty)
                        const _HintText('まだ日付がありません。「日付を追加」から追加してください。')
                      else
                        for (int di = 0; di < _days.length; di++) ...[
                          _DayCardLite(
                            dateText: _fmtDate(_days[di].date),
                            onDeleteDay: () => _removeDay(di),
                            onAddEntry: () => _addEntry(di),
                            child:
                                _days[di].entries.isEmpty
                                    ? const _HintText(
                                      'この日の予定は未登録です。「予定追加」から追加できます。',
                                    )
                                    : Column(
                                      children: [
                                        for (
                                          int ei = 0;
                                          ei < _days[di].entries.length;
                                          ei++
                                        ) ...[
                                          _EntryRowLite(
                                            timeText: _timeLabel(
                                              _days[di].entries[ei].time,
                                            ),
                                            typeText:
                                                _days[di].entries[ei].type,
                                            titleText:
                                                _days[di].entries[ei].title.text
                                                    .trim(),
                                            hasMemo:
                                                _days[di].entries[ei].memo.text
                                                    .trim()
                                                    .isNotEmpty,
                                            onEdit: () => _editEntry(di, ei),
                                            onDelete:
                                                () => _confirmAndRemoveEntry(
                                                  di,
                                                  ei,
                                                ),
                                          ),
                                          if (ei !=
                                              _days[di].entries.length - 1)
                                            const SizedBox(height: 8),
                                        ],
                                      ],
                                    ),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ 保存ボタン + メニューバー（未入力ならグレーアウト）
        bottomNavigationBar: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaveEnabled() ? _save : null,
                    child: Text(_isSaving ? '保存中…' : '保存'),
                  ),
                ),
              ),
              const Divider(height: 1),
              BottomNavigationBar(
                currentIndex: _menuIndex,
                onTap: (i) => _onTapMenu(i),
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt),
                    label: '旅行一覧',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.edit_note),
                    label: '作成',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.schedule),
                    label: 'スケジュール',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: '設定',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== 日付フィールド（見た目だけ軽く）=====
class _DatePickerField extends StatelessWidget {
  final Widget label;
  final String valueText;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.valueText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          label: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month),
            const SizedBox(width: 10),
            Expanded(child: Text(valueText)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// ===== 予定の行（タイムライン無しで工数削減）=====
class _EntryRowLite extends StatelessWidget {
  final String timeText;
  final String typeText;
  final String titleText;
  final bool hasMemo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryRowLite({
    required this.timeText,
    required this.typeText,
    required this.titleText,
    required this.hasMemo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = titleText.trim().isEmpty ? '（未入力）' : titleText.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 56),
              child: Text(
                timeText,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ChipLite(typeText),
                      const SizedBox(width: 8),
                      if (hasMemo)
                        const Icon(
                          Icons.note_alt_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ) ??
                        const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '編集',
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: '削除',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipLite extends StatelessWidget {
  final String text;
  const _ChipLite(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

/// ===== 予定追加/編集ダイアログ（1本化：時刻＋種別＋タイトル＋説明＋メモ）=====
class _AddOrEditEntryDialog extends StatefulWidget {
  final List<String> typeOptions;
  final List<String> transportOptions;

  final TimeOfDay? initialTime;
  final String? initialType;
  final String? initialTitle;
  final String? initialDesc;
  final String? initialMemo;
  final String? initialTransport;

  const _AddOrEditEntryDialog({
    required this.typeOptions,
    required this.transportOptions,
    this.initialTime,
    this.initialType,
    this.initialTitle,
    this.initialDesc,
    this.initialMemo,
    this.initialTransport,
  });

  @override
  State<_AddOrEditEntryDialog> createState() => _AddOrEditEntryDialogState();
}

class _AddOrEditEntryDialogState extends State<_AddOrEditEntryDialog> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  TimeOfDay? _time;
  String _type = 'その他';
  String _transport = '未設定';

  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _memo;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
    _type = widget.initialType ?? 'その他';
    _transport = widget.initialTransport ?? '未設定';
    _title = TextEditingController(text: widget.initialTitle ?? '');
    _desc = TextEditingController(text: widget.initialDesc ?? '');
    _memo = TextEditingController(text: widget.initialMemo ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final initial = _time ?? const TimeOfDay(hour: 10, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: '時刻を選択',
      confirmText: '決定',
      cancelText: 'キャンセル',
    );
    if (!mounted || picked == null) return;
    setState(() => _time = picked);
  }

  String _timeText() {
    if (_time == null) return '未設定';
    final hh = _time!.hour.toString().padLeft(2, '0');
    final mm = _time!.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _requiredLabel(BuildContext context, String text) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final style =
        Theme.of(context).textTheme.labelLarge ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    return RichText(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: onSurface),
        children: const [
          TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  void _submit() {
    final form = _key.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    Navigator.pop(
      context,
      ScheduleEntryValue(
        time: _time,
        type: _type,
        transport: _transport,
        title: _title.text.trim(),
        desc: _desc.text.trim(),
        memo: _memo.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialTitle != null;

    return AlertDialog(
      title: Text(isEdit ? '予定編集' : '予定追加'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _key,
          child: SingleChildScrollView(
            child: Column(
              children: [
                InkWell(
                  onTap: _pickTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '時刻（集合/移動/到着など）',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_timeText())),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _type,
                  items:
                      widget.typeOptions
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _type = v ?? 'その他'),
                  decoration: const InputDecoration(
                    labelText: '種別',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _transport,
                  items:
                      widget.transportOptions
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _transport = v ?? '未設定'),
                  decoration: const InputDecoration(
                    labelText: '移動手段',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(
                    label: _requiredLabel(context, 'タイトル'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'タイトルを入力してください';
                    if (t.length > 80) return '80文字以内で入力してください';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '説明',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _memo,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'メモ（テキストのみ）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

/// ===== UI部品 =====
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final TextStyle titleStyle;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.titleStyle,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final String text;
  const _HintText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
    );
  }
}

class _DayCardLite extends StatelessWidget {
  final String dateText;
  final VoidCallback onDeleteDay;
  final VoidCallback onAddEntry;
  final Widget child;

  const _DayCardLite({
    required this.dateText,
    required this.onDeleteDay,
    required this.onAddEntry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '日付を削除',
                  onPressed: onDeleteDay,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: onAddEntry,
                icon: const Icon(Icons.add),
                label: const Text('予定追加'),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// ===== Draft Models =====
class DayDraft {
  final DateTime date;
  final List<ScheduleEntryDraft> entries = [];

  DayDraft({required this.date});

  void dispose() {
    for (final e in entries) {
      e.dispose();
    }
  }
}

class ScheduleEntryDraft {
  TimeOfDay? time;
  String type;
  String transport;

  final TextEditingController title;
  final TextEditingController desc;
  final TextEditingController memo;

  ScheduleEntryDraft({
    required this.time,
    required this.type,
    required this.transport,
    required this.title,
    required this.desc,
    required this.memo,
  });

  factory ScheduleEntryDraft.fromValue(ScheduleEntryValue v) {
    return ScheduleEntryDraft(
      time: v.time,
      type: v.type,
      transport: v.transport,
      title: TextEditingController(text: v.title),
      desc: TextEditingController(text: v.desc),
      memo: TextEditingController(text: v.memo),
    );
  }

  void dispose() {
    title.dispose();
    desc.dispose();
    memo.dispose();
  }
}

class ScheduleEntryValue {
  final TimeOfDay? time;
  final String type;
  final String transport;

  final String title;
  final String desc;
  final String memo;

  const ScheduleEntryValue({
    required this.time,
    required this.type,
    required this.transport,
    required this.title,
    required this.desc,
    required this.memo,
  });
}

/// common_logo.dart 相当（assetsが無くても落ちないようにerrorBuilder付き）
class CommonLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const CommonLogo({super.key, required this.iconSize, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Image.asset(
          'assets/images/logo.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.card_travel, size: iconSize),
        ),
        const SizedBox(width: 8),
        Text(
          '旅リアン',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
