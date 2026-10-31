import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/providers.dart';
import '../../data/repositories/mock/afterlife_repository.dart';
import '../home/home_screen.dart';

final entrustedRecordsProvider =
    FutureProvider.autoDispose<List<EntrustedRecord>>(
      (ref) => ref.watch(afterlifeRepositoryProvider).listEntrusted(),
    );
final receivedMessagesProvider =
    FutureProvider.autoDispose<List<ReceivedMessage>>(
      (ref) => ref.watch(afterlifeRepositoryProvider).listReceivedMessages(),
    );

class AfterlifeScreen extends ConsumerWidget {
  const AfterlifeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('맡은 기록'),
        centerTitle: true,
        bottom: const TabBar(
          tabs: [
            Tab(text: '맡은 기록'),
            Tab(text: '받은 말'),
          ],
        ),
      ),
      body: const TabBarView(children: [_EntrustedList(), _ReceivedList()]),
    ),
  );
}

class _EntrustedList extends ConsumerWidget {
  const _EntrustedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(entrustedRecordsProvider);
    return records.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(entrustedRecordsProvider),
          child: const Text('기록을 불러오지 못했어요. 다시 시도'),
        ),
      ),
      data: (items) => items.isEmpty
          ? const _EmptyAfterlife('아직 맡은 기록이 없어요.')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final record in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.inkDeep,
                      child: Text(
                        record.ownerName.isEmpty
                            ? '?'
                            : record.ownerName.substring(0, 1),
                        style: const TextStyle(color: AppColors.white),
                      ),
                    ),
                    title: Text(
                      '${record.ownerName} 님의 기록',
                      style: AppText.listTitle,
                    ),
                    subtitle: Text(
                      '${record.account.type?.label ?? '기타'} · ${record.legacyName}',
                      style: AppText.listCaption,
                    ),
                    trailing: Text(
                      record.status == EntrustedRecordStatus.done
                          ? '처리 완료'
                          : '처리 필요',
                      style: AppText.listCaption,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            EntrustedDetailScreen(recordId: record.id),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class EntrustedDetailScreen extends ConsumerStatefulWidget {
  const EntrustedDetailScreen({super.key, required this.recordId});
  final String recordId;

  @override
  ConsumerState<EntrustedDetailScreen> createState() =>
      _EntrustedDetailScreenState();
}

class _EntrustedDetailScreenState extends ConsumerState<EntrustedDetailScreen> {
  late Future<EntrustedRecord> _record = ref
      .read(afterlifeRepositoryProvider)
      .getEntrusted(widget.recordId);
  bool _busy = false;

  Future<void> _markDone() async {
    setState(() => _busy = true);
    try {
      final record = await ref
          .read(afterlifeRepositoryProvider)
          .markHandled(widget.recordId);
      if (!mounted) return;
      setState(() => _record = Future.value(record));
      ref.invalidate(entrustedRecordsProvider);
      ref.invalidate(homeSnapshotProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('처리 상태를 저장하지 못했어요.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('처리 상세'), centerTitle: true),
    body: FutureBuilder<EntrustedRecord>(
      future: _record,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return const Center(child: Text('기록을 불러오지 못했어요.'));
          }
          return const Center(child: CircularProgressIndicator());
        }
        final record = snapshot.data!;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Text('${record.ownerName} 님의 기록', style: AppText.screenTitle),
                  const SizedBox(height: 20),
                  Text(
                    record.account.type?.label ?? '기타',
                    style: AppText.section,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow('항목', record.account.name),
                  _DetailRow(
                    '처리 방식',
                    record.account.action?.kind.label ?? '미지정',
                  ),
                  _DetailRow(
                    '상태',
                    record.status == EntrustedRecordStatus.done
                        ? '처리 완료'
                        : '처리 필요',
                  ),
                  if (record.account.action?.message?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    Text('상세 지침', style: AppText.section),
                    const SizedBox(height: 8),
                    Text(record.account.action!.message!, style: AppText.body),
                  ],
                  const SizedBox(height: 24),
                  Text('계정 정보', style: AppText.section),
                  _DetailRow('계정 ID', record.account.accountId ?? '등록되지 않음'),
                ],
              ),
            ),
            if (Env.useMockApi && record.status != EntrustedRecordStatus.done)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _markDone,
                      child: Text(_busy ? '처리 중' : '처리 완료로 기록'),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _ReceivedList extends ConsumerWidget {
  const _ReceivedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(receivedMessagesProvider);
    return messages.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(receivedMessagesProvider),
          child: const Text('받은 말을 불러오지 못했어요. 다시 시도'),
        ),
      ),
      data: (items) => items.isEmpty
          ? const _EmptyAfterlife('아직 받은 말이 없어요.')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${item.fromName} 님이 남긴 말',
                      style: AppText.listTitle,
                    ),
                    subtitle: Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.muted,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _ReceivedDetail(message: item),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ReceivedDetail extends StatelessWidget {
  const _ReceivedDetail({required this.message});
  final ReceivedMessage message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('받은 말'), centerTitle: true),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${message.fromName} 님이 남긴 말', style: AppText.screenTitle),
          const SizedBox(height: 28),
          Text(
            message.message,
            style: AppText.body.copyWith(color: AppColors.ink, fontSize: 16),
          ),
          const Spacer(),
          Text('작성자 · ${message.fromName}', style: AppText.listCaption),
        ],
      ),
    ),
  );
}

class _EmptyAfterlife extends StatelessWidget {
  const _EmptyAfterlife(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        Env.useMockApi
            ? message
            : '$message\n서버에 수신 기록 조회 API가 추가되면 이곳에서 확인할 수 있어요.',
        style: AppText.body,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        SizedBox(width: 92, child: Text(label, style: AppText.listCaption)),
        Expanded(
          child: Text(
            value,
            style: AppText.body.copyWith(color: AppColors.ink),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}
