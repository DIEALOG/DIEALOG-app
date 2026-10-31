import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/last_word.dart';
import '../../data/providers.dart';
import '../home/home_screen.dart';
import '../shared/audience_picker.dart';
import 'letter_draft_store.dart';
import 'letter_providers.dart';

class LetterEditScreen extends ConsumerStatefulWidget {
  const LetterEditScreen({super.key, required this.overview, this.letter});

  final LetterOverview overview;
  final LastWord? letter;

  @override
  ConsumerState<LetterEditScreen> createState() => _LetterEditScreenState();
}

class _LetterEditScreenState extends ConsumerState<LetterEditScreen> {
  late final _title = TextEditingController(text: widget.letter?.title ?? '');
  late final _message = TextEditingController(
    text: widget.letter?.message ?? '',
  );
  late AudienceSelection _selection = AudienceSelection(
    people: {...?widget.letter?.receiverIds},
    groups: {...?widget.letter?.receiverGroupIds},
  );
  Future<void> _lastWrite = Future<void>.value();
  Timer? _timer;
  DateTime? _savedAt;
  var _ready = false;
  var _busy = false;
  var _published = false;
  String? _error;

  String get _draftId => widget.letter?.id ?? 'new';

  @override
  void initState() {
    super.initState();
    Future.microtask(_restore);
  }

  Future<void> _restore() async {
    try {
      final draft = await ref
          .read(letterDraftStoreProvider)
          .read(widget.overview.userId, _draftId);
      if (draft != null && mounted) {
        _title.text = draft.title;
        _message.text = draft.message;
        _selection = AudienceSelection(
          people: draft.receiverIds.toSet(),
          groups: draft.receiverGroupIds.toSet(),
        );
        _savedAt = draft.savedAt;
      }
    } catch (_) {
      // The server copy is still editable when local storage is unavailable.
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  LetterDraft _draft() => LetterDraft(
    title: _title.text,
    message: _message.text,
    receiverIds: _selection.people.toList(),
    receiverGroupIds: _selection.groups.toList(),
    savedAt: DateTime.now(),
  );

  Future<void> _persistDraft() {
    final draft = _draft();
    final store = ref.read(letterDraftStoreProvider);
    final userId = widget.overview.userId;
    final draftId = _draftId;
    final next = _lastWrite
        .catchError((Object _) {})
        .then((_) => store.write(userId, draftId, draft));
    _lastWrite = next;
    next
        .then((_) {
          if (mounted) setState(() => _savedAt = draft.savedAt);
        })
        .catchError((Object _) {});
    return next;
  }

  void _changed() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 600), () {
      unawaited(_persistDraft().catchError((Object _) {}));
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_ready && !_published) {
      unawaited(_persistDraft().catchError((Object _) {}));
    }
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickAudience() async {
    final selected = await Navigator.of(context).push<AudienceSelection>(
      MaterialPageRoute(
        builder: (_) =>
            _AudienceScreen(overview: widget.overview, initial: _selection),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selection = selected);
      _changed();
    }
  }

  Future<void> _save() async {
    if (_busy || !_ready) return;
    final title = _title.text.trim();
    final message = _message.text.trim();
    if (title.isEmpty || message.isEmpty) {
      setState(() => _error = '제목과 내용을 입력해 주세요.');
      return;
    }
    if (_selection.resolvedIds(widget.overview.groups).isEmpty) {
      setState(() => _error = '받는 사람을 선택해 주세요.');
      return;
    }
    _timer?.cancel();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _lastWrite.catchError((Object _) {});
      final value = LastWord(
        title: title,
        message: message,
        receiverIds: _selection.people.toList(),
        receiverGroupIds: _selection.groups.toList(),
      );
      final repo = ref.read(lastWordRepositoryProvider);
      if (widget.letter == null) {
        await repo.create(value);
      } else {
        await repo.update(widget.letter!.id, value);
      }
      _published = true;
      try {
        await ref
            .read(letterDraftStoreProvider)
            .delete(widget.overview.userId, _draftId);
      } catch (_) {
        // The server write succeeded; local cleanup must not retry the write.
      }
      ref.invalidate(letterOverviewProvider);
      ref.invalidate(homeSnapshotProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('남기는 말을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    _timer?.cancel();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _lastWrite.catchError((Object _) {});
      await ref.read(lastWordRepositoryProvider).delete(widget.letter!.id);
      _published = true;
      try {
        await ref
            .read(letterDraftStoreProvider)
            .delete(widget.overview.userId, _draftId);
      } catch (_) {
        // The server delete already succeeded.
      }
      ref.invalidate(letterOverviewProvider);
      ref.invalidate(homeSnapshotProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '삭제하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final recipients = _selection.resolvedIds(widget.overview.groups);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      _savedAt == null ? '' : '방금 임시 저장됨',
                      textAlign: TextAlign.center,
                      style: AppText.listCaption,
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _save,
                    child: Text('저장', style: AppText.section),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  InkWell(
                    onTap: _pickAudience,
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              recipients.isEmpty
                                  ? '받는 사람을 선택해 주세요'
                                  : 'To. ${widget.overview.recipientLabel(LastWord(title: '', message: '', receiverIds: _selection.people.toList(), receiverGroupIds: _selection.groups.toList()))}',
                              style: AppText.listTitle,
                            ),
                          ),
                          Text('변경', style: AppText.listCaption),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  TextField(
                    controller: _title,
                    onChanged: (_) => _changed(),
                    style: AppText.screenTitle,
                    decoration: const InputDecoration(
                      hintText: '제목',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  TextField(
                    controller: _message,
                    onChanged: (_) => _changed(),
                    minLines: 16,
                    maxLines: null,
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      height: 27.75 / 15,
                      color: AppColors.ink,
                    ),
                    decoration: const InputDecoration(
                      hintText: '전하고 싶은 말을 적어 주세요.',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  if (widget.letter != null)
                    TextButton(
                      onPressed: _busy ? null : _delete,
                      child: const Text(
                        '남기는 말 삭제',
                        style: TextStyle(color: AppColors.unread),
                      ),
                    ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.unread),
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

class _AudienceScreen extends StatefulWidget {
  const _AudienceScreen({required this.overview, required this.initial});

  final LetterOverview overview;
  final AudienceSelection initial;

  @override
  State<_AudienceScreen> createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<_AudienceScreen> {
  late AudienceSelection _selection = widget.initial;

  @override
  Widget build(BuildContext context) {
    final ids = _selection.resolvedIds(widget.overview.groups);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      '받는 사람 선택',
                      style: AppText.section,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: AudiencePicker(
                people: widget.overview.people,
                groups: widget.overview.groups,
                selection: _selection,
                onChanged: (selection) =>
                    setState(() => _selection = selection),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  Text('${ids.length}명 선택', style: AppText.listCaption),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: '다음',
                    enabled: ids.isNotEmpty,
                    onPressed: () => Navigator.pop(context, _selection),
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
