import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_icon.dart';
import '../../data/models/last_word.dart';
import 'letter_edit_screen.dart';
import 'letter_providers.dart';

class LettersScreen extends ConsumerWidget {
  const LettersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(letterOverviewProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
          child: Row(
            children: [
              Text('남기는 말', style: AppText.screenTitle),
              const Spacer(),
              IconButton(
                tooltip: '남기는 말 작성',
                onPressed: snapshot.value == null
                    ? null
                    : () => _open(context, ref, snapshot.value!, null),
                icon: const AppIcon('assets/icons/icon_plus.svg', size: 24),
              ),
            ],
          ),
        ),
        Expanded(
          child: snapshot.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException ? error.message : '남기는 말을 불러오지 못했어요.',
                    style: AppText.body,
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(letterOverviewProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (data) => RefreshIndicator(
              onRefresh: () async => ref.refresh(letterOverviewProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  if (data.letters.isEmpty && data.newDraft == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Text(
                        '아직 남긴 말이 없어요.\n오른쪽 위 +에서 작성해 보세요.',
                        style: AppText.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (data.newDraft != null)
                    _LetterRow(
                      title: data.newDraft!.title.isEmpty
                          ? '제목 없음'
                          : data.newDraft!.title,
                      preview: data.newDraft!.message,
                      to: _recipientLabel(
                        data.newDraft!.receiverIds,
                        data.newDraft!.receiverGroupIds,
                        data,
                      ),
                      trailing: '작성 중',
                      onTap: () => _open(context, ref, data, null),
                    ),
                  for (final letter in data.letters)
                    _LetterRow(
                      title: letter.title,
                      preview: letter.message,
                      to: data.recipientLabel(letter),
                      onTap: () => _open(context, ref, data, letter),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _recipientLabel(
    List<String> people,
    List<String> groups,
    LetterOverview overview,
  ) => overview.recipientLabel(
    LastWord(
      title: '',
      message: '',
      receiverIds: people,
      receiverGroupIds: groups,
    ),
  );

  static Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    LetterOverview data,
    LastWord? letter,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LetterEditScreen(overview: data, letter: letter),
      ),
    );
    ref.invalidate(letterOverviewProvider);
  }
}

class _LetterRow extends StatelessWidget {
  const _LetterRow({
    required this.title,
    required this.preview,
    required this.to,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String preview;
  final String to;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.mail_outline, size: 18, color: AppColors.muted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'To. $to',
                        style: AppText.listCaption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null)
                      Text(trailing!, style: AppText.listCaption),
                  ],
                ),
                const SizedBox(height: 8),
                Text(title, style: AppText.listTitle),
                const SizedBox(height: 5),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
