import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/last_word.dart';
import '../../data/models/stakeholder.dart';
import '../../data/providers.dart';
import '../home/home_screen.dart';
import '../stakeholder/group_edit_screen.dart';
import '../stakeholder/people_providers.dart';
import '../shared/audience_picker.dart';
import '../shared/audience_select_screen.dart';
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
  late List<Stakeholder> _availablePeople = widget.overview.people;
  late List<StakeholderGroup> _availableGroups = widget.overview.groups;
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

  String _recipientLabel(Set<String> ids) {
    if (_selection.people.isEmpty && _selection.groups.isNotEmpty) {
      final groupNames = _availableGroups
          .where((group) => _selection.groups.contains(group.id))
          .map((group) => group.name)
          .toList();
      if (groupNames.length == 1) return groupNames.single;
      if (groupNames.length > 1) {
        return '${groupNames.first} 외 ${groupNames.length - 1}개 그룹';
      }
    }
    final firstId = ids.first;
    final name =
        _availablePeople
            .where((person) => person.id == firstId)
            .map((person) => person.name)
            .firstOrNull ??
        '관계자';
    return ids.length == 1 ? name : '$name 외 ${ids.length - 1}명';
  }

  Future<List<StakeholderGroup>> _createGroup() async {
    try {
      final overview = await ref.read(peopleOverviewProvider.future);
      if (!mounted) return _availableGroups;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GroupEditScreen(overview: overview),
        ),
      );
      final groups = await ref.read(stakeholderRepositoryProvider).listGroups();
      if (mounted) setState(() => _availableGroups = groups);
      return groups;
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.userMessage)));
      }
      return _availableGroups;
    }
  }

  Future<void> _pickAudience() async {
    try {
      final repository = ref.read(stakeholderRepositoryProvider);
      final people = await repository.list();
      final groups = await repository.listGroups();
      if (!mounted) return;
      setState(() {
        _availablePeople = people;
        _availableGroups = groups;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
      return;
    }
    if (!mounted) return;
    final selected = await Navigator.of(context).push<AudienceSelection>(
      MaterialPageRoute(
        builder: (_) => AudienceSelectScreen(
          title: '관계자에게 남기기',
          people: _availablePeople,
          groups: _availableGroups,
          initial: _selection,
          onCreateGroup: _createGroup,
        ),
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
    if (_selection.resolvedIds(_availableGroups).isEmpty) {
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

  /// True once there is something a delete would actually throw away: either a
  /// saved letter or an unsaved draft with text in it.
  bool get _deletable =>
      widget.letter != null ||
      _title.text.trim().isNotEmpty ||
      _message.text.trim().isNotEmpty;

  Future<void> _delete() async {
    final saved = widget.letter != null;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(saved ? '남기는 말을 삭제할까요?' : '작성 중인 글을 지울까요?'),
        content: Text(
          saved
              ? '받는 사람에게 전달되지 않고 사라져요. 되돌릴 수 없어요.'
              : '임시 저장된 내용이 사라져요. 되돌릴 수 없어요.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              saved ? '삭제' : '지우기',
              style: const TextStyle(color: AppColors.unread),
            ),
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
      if (saved) {
        await ref.read(lastWordRepositoryProvider).delete(widget.letter!.id);
      }
      // Stops dispose from writing the draft back out again.
      _published = true;
      try {
        await ref
            .read(letterDraftStoreProvider)
            .delete(widget.overview.userId, _draftId);
      } catch (_) {
        // A saved letter is already gone from the server; only the local
        // scratch copy is at stake here.
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
    final recipients = _selection.resolvedIds(_availableGroups);
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
                  if (_deletable)
                    IconButton(
                      tooltip: widget.letter == null ? '작성 중인 글 지우기' : '삭제',
                      onPressed: _busy ? null : _delete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 22,
                        color: AppColors.muted,
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
                                  : 'To. ${_recipientLabel(recipients)}',
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
