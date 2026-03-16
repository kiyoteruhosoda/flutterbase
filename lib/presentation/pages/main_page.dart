import 'package:flutter/material.dart';
import 'package:flutterbase/presentation/widgets/ui/widgets.dart';
import 'package:flutterbase/shared/theme/theme.dart';

/// メイン画面 (ホーム)
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const List<_TabItem> _tabs = [
    _TabItem(label: 'ホーム', icon: Icons.home_outlined, selectedIcon: Icons.home),
    _TabItem(
        label: '検索',
        icon: Icons.search_outlined,
        selectedIcon: Icons.search),
    _TabItem(
        label: '設定',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMainHeader(
        title: 'FlutterBase',
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'メニュー',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: '通知',
          ),
        ],
      ),
      drawer: AppDrawer(
        appName: 'FlutterBase',
        headerSubtitle: 'デジタル庁デザインシステム準拠',
        items: [
          AppDrawerItem(
            label: 'ホーム',
            icon: Icons.home_outlined,
            isSelected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.of(context).pop();
            },
          ),
          AppDrawerItem(
            label: '検索',
            icon: Icons.search_outlined,
            isSelected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.of(context).pop();
            },
          ),
          AppDrawerItem(
            label: '設定',
            icon: Icons.settings_outlined,
            isSelected: _selectedIndex == 2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              Navigator.of(context).pop();
            },
          ),
          const AppDrawerItem.divider(),
        ],
        bottomItems: [
          AppDrawerItem(
            label: 'バージョン情報',
            icon: Icons.info_outline,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/about');
            },
          ),
          AppDrawerItem(
            label: 'ライセンス',
            icon: Icons.description_outlined,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/licenses');
            },
          ),
          AppDrawerItem(
            label: 'デバッグ情報',
            icon: Icons.bug_report_outlined,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/debug');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildTabContent(),
          ),
          AppMainFooter(
            appName: 'FlutterBase',
            version: '1.0.0',
            links: [
              AppFooterLink(
                label: 'バージョン情報',
                onTap: () => Navigator.of(context).pushNamed('/about'),
              ),
              AppFooterLink(
                label: 'ライセンス',
                onTap: () => Navigator.of(context).pushNamed('/licenses'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_selectedIndex) {
      0 => const _HomeContent(),
      1 => const _SearchContent(),
      2 => const _SettingsContent(),
      _ => const _HomeContent(),
    };
  }
}

// ─── Tab Content Widgets ─────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      children: [
        AppSectionHeader(title: 'ようこそ', subtitle: 'デジタル庁デザインシステム準拠アプリ'),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'デジタル庁デザインシステム',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'このアプリはデジタル庁が提供するデザインシステム（DADS）に準拠して構築されています。'
                'カラートークン、タイポグラフィ、スペーシングなどのデザイン仕様に従った一貫したUIを提供します。',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(title: 'コンポーネント例'),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: 'プライマリボタン',
          onPressed: () {},
          width: double.infinity,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: 'セカンダリボタン',
          onPressed: () {},
          width: double.infinity,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppTextField(
          label: 'テキスト入力',
          hint: 'テキストを入力してください',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppListCard(
          title: 'リストカード',
          subtitle: 'サブタイトルテキスト',
          leading: const Icon(Icons.article_outlined),
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.sm),
        AppListCard(
          title: 'アイテム 2',
          subtitle: 'サブタイトルテキスト',
          leading: const Icon(Icons.article_outlined),
          onTap: () {},
        ),
      ],
    );
  }
}

class _SearchContent extends StatelessWidget {
  const _SearchContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.pageMargin),
      child: Column(
        children: [
          AppTextField(
            label: '検索',
            hint: 'キーワードを入力',
            prefixIcon: Icon(Icons.search),
          ),
          SizedBox(height: AppSpacing.xxxl),
          AppEmptyView(
            message: '検索キーワードを入力してください',
            icon: Icons.search,
          ),
        ],
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      children: [
        AppSectionHeader(title: '設定'),
        const SizedBox(height: AppSpacing.lg),
        AppListCard(
          title: 'バージョン情報',
          leading: const Icon(Icons.info_outline),
          onTap: () => Navigator.of(context).pushNamed('/about'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppListCard(
          title: 'ライセンス',
          leading: const Icon(Icons.description_outlined),
          onTap: () => Navigator.of(context).pushNamed('/licenses'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppListCard(
          title: 'デバッグ情報',
          leading: const Icon(Icons.bug_report_outlined),
          onTap: () => Navigator.of(context).pushNamed('/debug'),
        ),
      ],
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
