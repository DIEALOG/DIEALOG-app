import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/env.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/profile.dart';
import '../../data/providers.dart';
import '../home/home_screen.dart';
import 'settings_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;
  String? _error;

  Future<void> _changeImage() async {
    if (_uploading) return;
    if (Env.useMockApi) {
      setState(() => _error = '사진 변경은 실제 서버 연결 시 사용할 수 있어요.');
      return;
    }
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() {
        _uploading = true;
        _error = null;
      });
      await ref.read(profileRepositoryProvider).updateImage(file.path);
      ref.invalidate(settingsProfileProvider);
      ref.invalidate(homeSnapshotProvider);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '사진을 변경하지 못했어요.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(settingsProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('프로필'), centerTitle: true),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(settingsProfileProvider),
            child: const Text('프로필을 불러오지 못했어요. 다시 시도'),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.inkDeep,
                    foregroundImage: _imageUrl(data) == null
                        ? null
                        : NetworkImage(_imageUrl(data)!),
                    child: Text(
                      data.name.isEmpty ? '?' : data.name.substring(0, 1),
                      style: AppText.screenTitle.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(data.name, style: AppText.screenTitle),
                  TextButton(
                    onPressed: _uploading ? null : _changeImage,
                    child: Text(_uploading ? '업로드 중' : '사진 변경'),
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.unread),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('기본 정보', style: AppText.section),
            const SizedBox(height: 8),
            _InfoRow('이름', data.name),
            _InfoRow('이메일', data.email),
            _InfoRow(
              '전화번호',
              data.phoneNumber?.isNotEmpty == true
                  ? data.phoneNumber!
                  : '등록되지 않음',
            ),
            const SizedBox(height: 28),
            Text('계정 관리', style: AppText.section),
            const SizedBox(height: 8),
            const _InfoRow('비밀번호 변경', '준비 중'),
            const _InfoRow('회원 탈퇴', '준비 중'),
          ],
        ),
      ),
    );
  }

  String? _imageUrl(Profile profile) {
    final path = profile.profileImagePath;
    if (path == null || path.isEmpty) return null;
    final base = Uri.parse(Env.apiBaseUrl);
    return base.resolve(path.startsWith('/') ? path : '/$path').toString();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 17),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        SizedBox(width: 105, child: Text(label, style: AppText.listCaption)),
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
