import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'si007.dart' as screen007;
import 'si010.dart';

const String kAppLogoAsset = 'assets/images/logo.png';
const double kBottomNavHeight = 64;

void main() {
  runApp(const WorthApp());
}

class WorthApp extends StatelessWidget {
  const WorthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '旅リアン',
      theme: ThemeData(useMaterial3: true),
      home: const TripPlanListPage(),
    );
  }
}

class Plan {
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const Plan({
    required this.title,
    required this.createdAt,
    this.startDate,
    this.endDate,
  });

  Plan copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return Plan(
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayDate {
    if (startDate == null || endDate == null) return '日付未設定';
    return '${_fmt(startDate!)} - ${_fmt(endDate!)}';
  }

  static String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y/$m/$day';
  }
}

enum SortType { createdDesc, createdAsc, dateNearest }

class _NavItem {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.builder,
  });
}

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        double maxWidth;
        if (width >= 1200) {
          maxWidth = 700;
        } else if (width >= 800) {
          maxWidth = 600;
        } else {
          maxWidth = width;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

class TripPlanListPage extends StatefulWidget {
  const TripPlanListPage({super.key});

  @override
  State<TripPlanListPage> createState() => _TripPlanListPageState();
}

class _TripPlanListPageState extends State<TripPlanListPage> {
  final List<Plan> plans = [
    Plan(
      title: '沖縄 2泊3日',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 3),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Plan(
      title: '大阪 食い倒れ旅',
      startDate: DateTime(2026, 6, 10),
      endDate: DateTime(2026, 6, 12),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Plan(
      title: '札幌 雪まつり',
      startDate: DateTime(2026, 2, 5),
      endDate: DateTime(2026, 2, 8),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  bool _showBottomNav = true;
  SortType _currentSort = SortType.createdDesc;

  late final List<_NavItem> _navItems = [
    _NavItem(
      label: '旅行情報一覧',
      icon: Icons.list,
      builder: (_) => const TripPlanListPage(),
    ),
    _NavItem(
      label: 'プロフィール',
      icon: Icons.person,
      // ✅ここが修正点：screen007 は別名なので screen007() はNG
      builder: (_) => const screen007.Screen007Page(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _applySort();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('更新しました（モック）')));
  }

  Future<void> _goToCreatePlan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Si010Page()),
    );
  }

  Future<void> _goToEditPlan(int index) async {
    final plan = plans[index];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Si010Page(initialPlanTitle: plan.title),
      ),
    );
  }

  void _applySort() {
    switch (_currentSort) {
      case SortType.createdDesc:
        plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.createdAsc:
        plans.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortType.dateNearest:
        final now = DateTime.now();

        int rank(Plan p) {
          if (p.startDate == null) return 1;
          return 0;
        }

        plans.sort((a, b) {
          final ra = rank(a);
          final rb = rank(b);
          if (ra != rb) return ra.compareTo(rb);

          final da = (a.startDate!.difference(now).inDays).abs();
          final db = (b.startDate!.difference(now).inDays).abs();
          final cmp = da.compareTo(db);
          if (cmp != 0) return cmp;

          return a.startDate!.compareTo(b.startDate!);
        });
        break;
    }
  }

  void _onSelectSort(SortType type) {
    setState(() {
      _currentSort = type;
      _applySort();
    });

    final label = switch (type) {
      SortType.createdDesc => '登録順（新しい順）',
      SortType.createdAsc => '登録順（古い順）',
      SortType.dateNearest => '日程が近い順',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('並び替え：$label')));
  }

  // ---------- ✅ 下メニュー遷移（2項目） ----------
  void _onBottomNavTap(int index) {
    if (index == 0) return; // 既に一覧
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: _navItems[index].builder),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      final dir = notification.direction;

      if (dir == ScrollDirection.reverse && _showBottomNav) {
        setState(() => _showBottomNav = false);
      }
      if (dir == ScrollDirection.forward && !_showBottomNav) {
        setState(() => _showBottomNav = true);
      }
    }
    return false;
  }

  Widget _buildLeadingBrand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          kAppLogoAsset,
          height: 26,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
        ),
        const SizedBox(width: 8),
        const Text(
          '旅リアン',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCenterTitle() {
    return const Text(
      '旅行情報一覧',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<SortType>(
      icon: const Icon(Icons.sort),
      tooltip: '並び替え',
      onSelected: _onSelectSort,
      itemBuilder:
          (context) => const [
            PopupMenuItem(
              value: SortType.createdDesc,
              child: Text('登録順（新しい順）'),
            ),
            PopupMenuItem(value: SortType.createdAsc, child: Text('登録順（古い順）')),
            PopupMenuItem(value: SortType.dateNearest, child: Text('日程が近い順')),
          ],
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        child: SizedBox(
          height: kBottomNavHeight,
          child: BottomNavigationBar(
            currentIndex: 0,
            onTap: _onBottomNavTap,
            type: BottomNavigationBarType.fixed,
            items:
                _navItems
                    .map(
                      (e) => BottomNavigationBarItem(
                        icon: Icon(e.icon),
                        label: e.label,
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 140,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _buildLeadingBrand(),
        ),
        centerTitle: true,
        title: _buildCenterTitle(),
        actions: [_buildSortMenu()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreatePlan,
        tooltip: '新規プラン作成',
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          ResponsiveWrapper(
            child: Padding(
              padding: const EdgeInsets.only(bottom: kBottomNavHeight),
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child:
                      plans.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 180),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.travel_explore,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '旅行プランがありません',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '上から下にスワイプして更新できます',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                          : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: plans.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final plan = plans[index];
                              return ListTile(
                                onTap: () => _goToEditPlan(index),
                                title: Text(
                                  plan.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    plan.displayDate,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              );
                            },
                          ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: _showBottomNav ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _showBottomNav ? 1 : 0,
                child: _buildBottomNav(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
