import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/account.dart';

/// One row of the service picker.
///
/// The API only knows the services in [AccountService]; anything else is sent
/// as `Other` with a free-form name, which is how iCloud and 네이버 are
/// offered here alongside 기타 서비스.
class ServiceChoice {
  const ServiceChoice(this.label, this.service, {this.name, this.custom = false});

  final String label;
  final AccountService service;

  /// Fixed name sent with `Other`.
  final String? name;

  /// Asks the user to type the service name.
  final bool custom;

  bool matches(AccountService? service, String? name) {
    if (service != this.service) return false;
    if (this.service != AccountService.other) return true;
    if (custom) return name != null && !_presetNames.contains(name);
    return name == this.name;
  }
}

const _presetNames = {'iCloud', '네이버'};

const serviceChoices = [
  ServiceChoice('Google', AccountService.google),
  ServiceChoice('Instagram', AccountService.instagram),
  ServiceChoice('iCloud', AccountService.other, name: 'iCloud'),
  ServiceChoice('카카오톡', AccountService.kakaoTalk),
  ServiceChoice('네이버', AccountService.other, name: '네이버'),
  ServiceChoice('Apple', AccountService.apple),
  ServiceChoice('Facebook', AccountService.facebook),
  ServiceChoice('Twitter', AccountService.twitter),
  ServiceChoice('Discord', AccountService.discord),
  ServiceChoice('Microsoft', AccountService.microsoft),
  ServiceChoice('GitHub', AccountService.gitHub),
  ServiceChoice('Telegram', AccountService.telegram),
  ServiceChoice('기타 서비스 (직접 입력)', AccountService.other, custom: true),
];

/// `10-2 · 선택 목록 열림`: picking a row applies it and closes; dismissing
/// keeps the current choice.
Future<ServiceChoice?> showServiceSheet(
  BuildContext context, {
  ServiceChoice? selected,
}) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<ServiceChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.inkDeep.withValues(alpha: 0.28),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _ServiceSheet(selected: selected),
  );
}

class _ServiceSheet extends StatefulWidget {
  const _ServiceSheet({this.selected});

  final ServiceChoice? selected;

  @override
  State<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<_ServiceSheet> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final matching = [
      for (final choice in serviceChoices)
        if (query.isEmpty || choice.label.toLowerCase().contains(query)) choice,
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 34),
      child: SizedBox(
        height: 640,
        child: Column(
          children: [
            SizedBox(
              height: 24,
              child: Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.fieldLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Row(
                  children: [
                    Text(
                      '서비스 선택',
                      style: AppText.serviceName.copyWith(
                        color: AppColors.inkDeep,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        foregroundColor: AppColors.muted,
                      ),
                      child: Text(
                        '닫기',
                        style: AppText.listCaption.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 21 / 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.search,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const AppIcon('assets/icons/icon_search.svg', size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (value) => setState(() => _query = value),
                        cursorColor: AppColors.navy,
                        style: AppText.greeting.copyWith(
                          color: AppColors.ink,
                          letterSpacing: 0,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(bottom: 2),
                          hintText: '서비스 검색',
                          hintStyle: AppText.greeting.copyWith(
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: matching.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                      child: Text(
                        '‘$_query’와 맞는 서비스가 없어요.\n기타 서비스로 직접 입력해 주세요.',
                        style: AppText.body,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final choice in matching)
                          _Option(
                            choice: choice,
                            selected: choice == widget.selected,
                            onTap: () => Navigator.of(context).pop(choice),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final ServiceChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: selected ? AppColors.optionSelected : AppColors.white,
        child: Row(
          children: [
            Expanded(
              child: Text(
                choice.label,
                style: AppText.rowValue.copyWith(
                  height: 24 / 15,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 12),
              const AppIcon('assets/icons/icon_check.svg', size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
