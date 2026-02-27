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
      home: const Si010Page(),
    );
  }
}

class Si010Page extends StatefulWidget {
  const Si010Page({super.key});

  @override
  State<Si010Page> createState() => _Si010PageState();
}

class _Si010PageState extends State<Si010Page> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _planTitleController = TextEditingController();

  // 概要（1つ固定）※タイトルは使わない想定だが互換で残す
  final TextEditingController _overviewTitle = TextEditingController();
  final TextEditingController _overviewContent = TextEditingController();

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

  static const List<String> _timeZoneOptions = <String>[
    'Asia/Tokyo',
    'UTC',
    'Asia/Seoul',
    'Asia/Singapore',
    'Asia/Bangkok',
    'America/Los_Angeles',
    'America/New_York',
    'Europe/London',
    'Europe/Paris',
    'Australia/Sydney',
  ];

  String _defaultDayTimeZone = 'Asia/Tokyo';
  final List<DayDraft> _days = [];

  bool _isSaving = false;
  int _menuIndex = 1;

  bool _isDirty = false;

  PlanVisibility _visibility = PlanVisibility.privateOnly;

  final ScrollController _scrollController = ScrollController();
  double _lastOffset = 0.0;
  bool _showBottomBar = true;
  static const double _toggleThreshold = 6.0;

  @override
  void initState() {
    super.initState();
    _planTitleController.addListener(_markDirty);
    _overviewTitle.addListener(_markDirty);
    _overviewContent.addListener(_markDirty);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();

    _planTitleController.removeListener(_markDirty);
    _overviewTitle.removeListener(_markDirty);
    _overviewContent.removeListener(_markDirty);

    _planTitleController.dispose();
    _overviewTitle.dispose();
    _overviewContent.dispose();

    for (final d in _days) {
      d.dispose();
    }
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;

    final current = _scrollController.position.pixels;
    final delta = current - _lastOffset;

    if (delta > _toggleThreshold) {
      if (_showBottomBar) setState(() => _showBottomBar = false);
      _lastOffset = current;
      return;
    }

    if (delta < -_toggleThreshold) {
      if (!_showBottomBar) setState(() => _showBottomBar = true);
      _lastOffset = current;
      return;
    }
  }

  void _markDirty() {
    if (!mounted) return;
    setState(() => _isDirty = true);
  }

  void _markSaved() {
    if (!mounted) return;
    setState(() => _isDirty = false);
  }

  bool get _isSaveEnabled => _planTitleController.text.trim().isNotEmpty;

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_isDirty) return true;

    final bool? discard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('未保存の変更があります'),
          content: const Text('この画面を離れると入力内容は破棄されます。破棄しますか？'),
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

  IconData? _transportIcon(String? transport) {
    switch ((transport ?? '').trim()) {
      case '電車':
        return Icons.train;
      case '飛行機':
        return Icons.flight;
      case 'バス':
        return Icons.directions_bus;
      case '徒歩':
        return Icons.directions_walk;
      case '車':
        return Icons.directions_car;
      case 'タクシー':
        return Icons.local_taxi;
      case '自転車':
        return Icons.directions_bike;
      case '船':
        return Icons.directions_boat;
      case 'その他':
        return Icons.more_horiz;
      case '未設定':
      default:
        return null;
    }
  }

  double _dialogWidth(
    BuildContext context, {
    double min = 280,
    double max = 520,
  }) {
    final w = MediaQuery.of(context).size.width * 0.92;
    return w.clamp(min, max);
  }

  // -----------------------
  // ✅ AppBar（Si005と同じ思想：中央タイトル固定＋見切れ対策）
  // -----------------------
  PreferredSizeWidget _buildResponsiveAppBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // 狭い端末では左の"旅リアン"を省略して、中央タイトルを優先
    final bool showAppName = width >= 360;

    // 左ブロックの幅を可変にして中央を潰しにくくする
    final double leftWidth = showAppName ? (width * 0.38).clamp(120, 180) : 64;

    return AppBar(
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      leadingWidth: leftWidth,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ロゴ（assets）
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported);
              },
            ),
            if (showAppName) ...[
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  '旅リアン',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),

      // titleは使わず、flexibleSpaceで中央固定
      title: const SizedBox.shrink(),
      flexibleSpace: SafeArea(
        child: Stack(
          children: const [
            Center(
              child: Text(
                'スケジュール管理',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------
  // ✅ 日付：追加（Date + TimeZone）
  // -----------------------
  Future<void> _addDay() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: '日付を選択',
      confirmText: '次へ',
      cancelText: 'キャンセル',
    );
    if (!mounted || picked == null) return;

    final String? tz = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String selected = _defaultDayTimeZone;
        return AlertDialog(
          title: const Text('タイムゾーンを選択'),
          content: SizedBox(
            width: _dialogWidth(context, min: 300, max: 520),
            child: DropdownButtonFormField<String>(
              value: selected,
              items:
                  _timeZoneOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              decoration: const InputDecoration(
                labelText: '基準タイムゾーン',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                if (v == null) return;
                selected = v;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
    if (!mounted || tz == null) return;

    final bool exists = _days.any(
      (d) => _sameDay(d.date, picked) && d.timeZone == tz,
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('同じ日付・同じタイムゾーンがすでに追加されています')),
      );
      return;
    }

    setState(() {
      _defaultDayTimeZone = tz;
      _days.add(DayDraft(date: picked, timeZone: tz));
      _days.sort((a, b) {
        final c = a.date.compareTo(b.date);
        if (c != 0) return c;
        return a.timeZone.compareTo(b.timeZone);
      });
      _isDirty = true;
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _removeDay(int index) {
    setState(() {
      _days[index].dispose();
      _days.removeAt(index);
      _isDirty = true;
    });
  }

  Future<void> _editDayTimeZone(int index) async {
    final current = _days[index];

    final String? tz = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String selected = current.timeZone;
        return AlertDialog(
          title: const Text('タイムゾーン変更'),
          content: SizedBox(
            width: _dialogWidth(context, min: 300, max: 520),
            child: DropdownButtonFormField<String>(
              value: selected,
              items:
                  _timeZoneOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              decoration: const InputDecoration(
                labelText: '基準タイムゾーン',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                if (v == null) return;
                selected = v;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('変更'),
            ),
          ],
        );
      },
    );

    if (!mounted || tz == null) return;

    final bool exists = _days.any(
      (d) => _sameDay(d.date, current.date) && d.timeZone == tz && d != current,
    );
    if (exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('同じ日付・同じタイムゾーンが既にあります')));
      return;
    }

    setState(() {
      current.timeZone = tz;
      _defaultDayTimeZone = tz;
      _days.sort((a, b) {
        final c = a.date.compareTo(b.date);
        if (c != 0) return c;
        return a.timeZone.compareTo(b.timeZone);
      });
      _isDirty = true;
    });
  }

  // -----------------------
  // 予定：追加・編集・削除
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

  Future<void> _addScheduleEntry(int dayIndex) async {
    final ScheduleEntryValue? created = await showDialog<ScheduleEntryValue>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _AddOrEditScheduleEntryDialog(
            transportOptions: _transportOptions,
          ),
    );
    if (!mounted || created == null) return;

    setState(() {
      _days[dayIndex].entries.add(
        ScheduleEntryDraft.fromValue(created, onChanged: _markDirty),
      );
      _days[dayIndex].entries.sort(_entrySort);
      _isDirty = true;
    });
  }

  Future<void> _editScheduleEntry(int dayIndex, int entryIndex) async {
    final entry = _days[dayIndex].entries[entryIndex];

    final ScheduleEntryValue? edited = await showDialog<ScheduleEntryValue>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _AddOrEditScheduleEntryDialog(
            transportOptions: _transportOptions,
            initialTime: entry.time,
            initialTitle: entry.title.text,
            initialDesc: entry.desc.text,
            initialTransport: entry.transport ?? '未設定',
          ),
    );
    if (!mounted || edited == null) return;

    setState(() {
      entry.time = edited.time;
      entry.title.text = edited.title;
      entry.desc.text = edited.desc;
      entry.transport = edited.transport;
      _days[dayIndex].entries.sort(_entrySort);
      _isDirty = true;
    });
  }

  void _removeScheduleEntry(int dayIndex, int entryIndex) {
    setState(() {
      _days[dayIndex].entries[entryIndex].dispose();
      _days[dayIndex].entries.removeAt(entryIndex);
      _isDirty = true;
    });
  }

  // -----------------------
  // メモ
  // -----------------------
  Future<void> _openMemoEditor({required ScheduleEntryDraft entry}) async {
    final String initial = entry.memo ?? '';
    final TextEditingController c = TextEditingController(text: initial);

    final _MemoResult? result = await showDialog<_MemoResult>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _MemoDialog(controller: c, hasMemo: initial.trim().isNotEmpty),
    );

    if (!mounted) return;
    if (result == null) return;

    setState(() {
      if (result.action == _MemoAction.delete) {
        entry.memo = null;
      } else if (result.action == _MemoAction.save) {
        final v = c.text.trim();
        entry.memo = v.isEmpty ? null : v;
      }
      _isDirty = true;
    });
  }

  Future<void> _openEntryMenu({
    required int dayIndex,
    required int entryIndex,
  }) async {
    final selected = await showModalBottomSheet<_EntryMenuAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('予定を編集'),
                  onTap: () => Navigator.pop(context, _EntryMenuAction.edit),
                ),
                ListTile(
                  leading: const Icon(Icons.note_alt_outlined),
                  title: const Text('メモを追加/編集'),
                  onTap: () => Navigator.pop(context, _EntryMenuAction.memo),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('予定を削除'),
                  onTap: () => Navigator.pop(context, _EntryMenuAction.delete),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    if (selected == _EntryMenuAction.edit) {
      await _editScheduleEntry(dayIndex, entryIndex);
    } else if (selected == _EntryMenuAction.memo) {
      await _openMemoEditor(entry: _days[dayIndex].entries[entryIndex]);
    } else if (selected == _EntryMenuAction.delete) {
      _removeScheduleEntry(dayIndex, entryIndex);
    }
  }

  // -----------------------
  // 保存
  // -----------------------
  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _isSaving = false);

    _markSaved();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('保存しました：日付${_days.length}件')));
  }

  Future<void> _onTapMenu(int index) async {
    if (index == _menuIndex) return;

    final ok = await _confirmDiscardIfNeeded();
    if (!ok) return;

    setState(() {
      _menuIndex = index;
      _isDirty = false;
    });

    const labels = ['旅行一覧', '作成', 'スケジュール', '設定'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「${labels[index]}」は未実装（ここに画面遷移を追加）')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        Theme.of(context).textTheme.titleMedium ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    final hintStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey) ??
        const TextStyle(color: Colors.grey);

    final bool canSave = (!_isSaving && _isSaveEnabled);

    final Widget bottomBar = SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ max幅 520 に揃える（Si005と同じ）
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canSave ? _save : null,
                    child: Text(_isSaving ? '保存中…' : '保存'),
                  ),
                ),
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
              BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: '作成'),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule),
                label: 'スケジュール',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
            ],
          ),
        ],
      ),
    );

    return WillPopScope(
      onWillPop: () async => _confirmDiscardIfNeeded(),
      child: Scaffold(
        appBar: _buildResponsiveAppBar(context),

        // ✅ ここが「Si005と同じサイズ感」の肝：maxWidth 520 に統一
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 180),
                  children: [
                    _SectionCard(
                      title: '旅行タイトル',
                      subtitle: 'プラン内のタイトルとして表示します',
                      titleStyle: titleStyle,
                      child: TextFormField(
                        controller: _planTitleController,
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
                    ),
                    const SizedBox(height: 12),

                    _SectionCard(
                      title: '概要',
                      subtitle: '内容',
                      titleStyle: titleStyle,
                      child: TextField(
                        controller: _overviewContent,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: '旅行プランの概要',
                          hintStyle: hintStyle,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _SectionCard(
                      title: 'スケジュール',
                      subtitle: '日付を追加し、その日付に予定を追加します',
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
                              _DayCardModern(
                                dateText: _fmtDate(_days[di].date),
                                timeZone: _days[di].timeZone,
                                onEditTimeZone: () => _editDayTimeZone(di),
                                onDeleteDay: () => _removeDay(di),
                                onAddEntry: () => _addScheduleEntry(di),
                                child:
                                    _days[di].entries.isEmpty
                                        ? const _HintText(
                                          'この日の予定は未登録です。「予定追加」から追加できます。',
                                        )
                                        : _Timeline(
                                          entries: _days[di].entries,
                                          buildItem: (i, isFirst, isLast) {
                                            final e = _days[di].entries[i];
                                            return _TimelineItemWide(
                                              isFirst: isFirst,
                                              isLast: isLast,
                                              railColor:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.outline,
                                              timeText: _timeLabel(e.time),
                                              titleText: e.title.text.trim(),
                                              descText: e.desc.text.trim(),
                                              memoText: (e.memo ?? '').trim(),
                                              transportIcon: _transportIcon(
                                                e.transport,
                                              ),
                                              transportLabel:
                                                  (e.transport ?? '')
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : e.transport,
                                              onOpenMenu:
                                                  () => _openEntryMenu(
                                                    dayIndex: di,
                                                    entryIndex: i,
                                                  ),
                                            );
                                          },
                                        ),
                              ),
                              const SizedBox(height: 12),
                            ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    _SectionCard(
                      title: '公開設定',
                      subtitle: '作成した旅行プランの公開範囲を設定します',
                      titleStyle: titleStyle,
                      child: Column(
                        children: [
                          RadioListTile<PlanVisibility>(
                            value: PlanVisibility.privateOnly,
                            groupValue: _visibility,
                            title: const Text('非公開（自分のみ）'),
                            subtitle: const Text('このプランは自分だけが閲覧できます'),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _visibility = v;
                                _isDirty = true;
                              });
                            },
                          ),
                          RadioListTile<PlanVisibility>(
                            value: PlanVisibility.groupShare,
                            groupValue: _visibility,
                            title: const Text('グループ共有（招待メンバー）'),
                            subtitle: const Text('招待したメンバーと閲覧/編集できます'),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _visibility = v;
                                _isDirty = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        bottomNavigationBar: AnimatedSlide(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          offset: _showBottomBar ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: _showBottomBar ? 1 : 0,
            child: bottomBar,
          ),
        ),
      ),
    );
  }
}

/// 公開範囲
enum PlanVisibility { privateOnly, groupShare }

/// ===== タイムライン =====
class _Timeline extends StatelessWidget {
  final List<ScheduleEntryDraft> entries;
  final Widget Function(int index, bool isFirst, bool isLast) buildItem;

  const _Timeline({required this.entries, required this.buildItem});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          buildItem(i, i == 0, i == entries.length - 1),
          if (i != entries.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// タイムラインアイテム（カードの高さに合わせてレール＆時刻）
class _TimelineItemWide extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Color railColor;

  final String timeText;
  final String titleText;
  final String descText;
  final String memoText;

  final IconData? transportIcon;
  final String? transportLabel;

  final VoidCallback onOpenMenu;

  const _TimelineItemWide({
    required this.isFirst,
    required this.isLast,
    required this.railColor,
    required this.timeText,
    required this.titleText,
    required this.descText,
    required this.memoText,
    required this.transportIcon,
    required this.transportLabel,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    const double railWidth = 28;
    const double gapRailToTime = 6;

    final screenW = MediaQuery.of(context).size.width;
    final double timeWidth = screenW < 360 ? 48 : 56;
    const double gapTimeToCard = 8;

    final double leftPad =
        railWidth + gapRailToTime + timeWidth + gapTimeToCard;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(left: leftPad),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          titleText.isEmpty ? '（未入力）' : titleText,
                          softWrap: true,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ) ??
                              const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (transportIcon != null) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: transportLabel ?? '',
                          child: Icon(
                            transportIcon,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      IconButton(
                        tooltip: 'メニュー',
                        icon: const Icon(Icons.more_horiz),
                        onPressed: onOpenMenu,
                      ),
                    ],
                  ),
                  if (descText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      descText,
                      softWrap: true,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  if (memoText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'メモ: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Expanded(
                          child: Text(
                            memoText,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: railWidth,
          child: CustomPaint(
            painter: _TimelineRailPainter(
              isFirst: isFirst,
              isLast: isLast,
              color: railColor,
            ),
          ),
        ),
        Positioned(
          left: railWidth + gapRailToTime,
          top: 0,
          bottom: 0,
          width: timeWidth,
          child: LayoutBuilder(
            builder: (context, c) {
              final h = c.maxHeight;
              final centerY = h / 2;
              final double shift = isFirst ? -16 : -8;

              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: (centerY + shift).clamp(0.0, h - 18),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        timeText,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimelineRailPainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color color;

  _TimelineRailPainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    if (!isFirst) canvas.drawLine(Offset(cx, 0), Offset(cx, cy), paint);
    if (!isLast)
      canvas.drawLine(Offset(cx, cy), Offset(cx, size.height), paint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TimelineRailPainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.color != color;
  }
}

/// ===== 予定追加/編集ダイアログ =====
class _AddOrEditScheduleEntryDialog extends StatefulWidget {
  final List<String> transportOptions;
  final TimeOfDay? initialTime;
  final String? initialTitle;
  final String? initialDesc;
  final String? initialTransport;

  const _AddOrEditScheduleEntryDialog({
    required this.transportOptions,
    this.initialTime,
    this.initialTitle,
    this.initialDesc,
    this.initialTransport,
  });

  @override
  State<_AddOrEditScheduleEntryDialog> createState() =>
      _AddOrEditScheduleEntryDialogState();
}

class _AddOrEditScheduleEntryDialogState
    extends State<_AddOrEditScheduleEntryDialog> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  TimeOfDay? _time;
  late final TextEditingController _title;
  late final TextEditingController _desc;
  String? _transport;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
    _title = TextEditingController(text: widget.initialTitle ?? '');
    _desc = TextEditingController(text: widget.initialDesc ?? '');
    _transport = widget.initialTransport ?? '未設定';
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay initial = _time ?? const TimeOfDay(hour: 10, minute: 0);
    final TimeOfDay? picked = await showTimePicker(
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
        title: _title.text.trim(),
        desc: _desc.text.trim(),
        transport: _transport ?? '未設定',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.initialTitle != null;
    final double w = (MediaQuery.of(context).size.width * 0.92).clamp(
      300.0,
      520.0,
    );

    return AlertDialog(
      title: Text(isEdit ? '予定編集' : '予定追加'),
      content: SizedBox(
        width: w,
        child: Form(
          key: _key,
          child: SingleChildScrollView(
            child: Column(
              children: [
                InkWell(
                  onTap: _pickTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '時刻',
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
                  value: _transport,
                  items:
                      widget.transportOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  decoration: const InputDecoration(
                    labelText: '移動手段',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _transport = v),
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
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '説明',
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

/// ===== メモダイアログ =====
enum _EntryMenuAction { edit, memo, delete }

enum _MemoAction { save, delete }

class _MemoResult {
  final _MemoAction action;
  const _MemoResult(this.action);
}

class _MemoDialog extends StatelessWidget {
  final TextEditingController controller;
  final bool hasMemo;

  const _MemoDialog({required this.controller, required this.hasMemo});

  @override
  Widget build(BuildContext context) {
    final double w = (MediaQuery.of(context).size.width * 0.92).clamp(
      300.0,
      520.0,
    );

    return AlertDialog(
      title: const Text('メモ'),
      content: SizedBox(
        width: w,
        child: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'メモを入力（テキストのみ）',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        if (hasMemo)
          TextButton(
            onPressed:
                () => Navigator.pop(
                  context,
                  const _MemoResult(_MemoAction.delete),
                ),
            child: const Text('削除'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed:
              () => Navigator.pop(context, const _MemoResult(_MemoAction.save)),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// ===== UI 部品 =====
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

class _DayCardModern extends StatelessWidget {
  final String dateText;
  final String timeZone;
  final VoidCallback onEditTimeZone;
  final VoidCallback onDeleteDay;
  final VoidCallback onAddEntry;
  final Widget child;

  const _DayCardModern({
    required this.dateText,
    required this.timeZone,
    required this.onEditTimeZone,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateText,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.public,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              timeZone,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: onEditTimeZone,
                            child: const Text('変更'),
                          ),
                        ],
                      ),
                    ],
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
  String timeZone;
  final List<ScheduleEntryDraft> entries = [];

  DayDraft({required this.date, required this.timeZone});

  void dispose() {
    for (final e in entries) {
      e.dispose();
    }
  }
}

class ScheduleEntryDraft {
  TimeOfDay? time;
  final TextEditingController title;
  final TextEditingController desc;

  String? memo;
  String? transport;

  final VoidCallback? onChanged;

  ScheduleEntryDraft({
    required this.time,
    required this.title,
    required this.desc,
    this.memo,
    this.transport,
    this.onChanged,
  }) {
    title.addListener(_handleChanged);
    desc.addListener(_handleChanged);
  }

  void _handleChanged() {
    onChanged?.call();
  }

  factory ScheduleEntryDraft.fromValue(
    ScheduleEntryValue v, {
    VoidCallback? onChanged,
  }) {
    return ScheduleEntryDraft(
      time: v.time,
      title: TextEditingController(text: v.title),
      desc: TextEditingController(text: v.desc),
      transport: v.transport,
      onChanged: onChanged,
    );
  }

  void dispose() {
    title.removeListener(_handleChanged);
    desc.removeListener(_handleChanged);
    title.dispose();
    desc.dispose();
  }
}

class ScheduleEntryValue {
  final TimeOfDay? time;
  final String title;
  final String desc;
  final String transport;

  const ScheduleEntryValue({
    required this.time,
    required this.title,
    required this.desc,
    required this.transport,
  });
}
