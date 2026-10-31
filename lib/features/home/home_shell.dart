import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_icon.dart';
import '../legacy/data_screen.dart';
import '../last_word/letters_screen.dart';
import '../settings/settings_screen.dart';
import '../stakeholder/people_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            DataScreen(),
            PeopleScreen(),
            LettersScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (final tab in _tabs)
                  Expanded(
                    child: _TabButton(
                      tab: tab,
                      selected: _index == tab.index,
                      onTap: () => setState(() => _index = tab.index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.index, this.label, this.icon);

  final int index;
  final String label;
  final String icon;
}

const _tabs = [
  _Tab(0, '홈', 'assets/icons/icon_tab_home.svg'),
  _Tab(1, '데이터', 'assets/icons/icon_tab_data.svg'),
  _Tab(2, '관계자', 'assets/icons/icon_tab_people.svg'),
  _Tab(3, '남기는 말', 'assets/icons/icon_tab_letters.svg'),
  _Tab(4, '설정', 'assets/icons/icon_tab_settings.svg'),
];

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.inkDeep : AppColors.muted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(tab.icon, size: 24, color: color),
          const SizedBox(height: 3),
          Text(
            tab.label,
            style: AppText.tab.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
