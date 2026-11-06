import 'package:flutter/material.dart';

import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/stakeholder.dart';
import 'audience_picker.dart';

class AudienceSelectScreen extends StatefulWidget {
  const AudienceSelectScreen({
    super.key,
    required this.people,
    required this.groups,
    required this.initial,
    this.allowEmpty = false,
    this.buttonLabel = '다음',
    this.title = '받는 사람 선택',
  });

  final List<Stakeholder> people;
  final List<StakeholderGroup> groups;
  final AudienceSelection initial;
  final bool allowEmpty;
  final String buttonLabel;
  final String title;

  @override
  State<AudienceSelectScreen> createState() => _AudienceSelectScreenState();
}

class _AudienceSelectScreenState extends State<AudienceSelectScreen> {
  late AudienceSelection _selection = widget.initial;

  @override
  Widget build(BuildContext context) {
    final count = _selection.resolvedIds(widget.groups).length;
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
                      widget.title,
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
                people: widget.people,
                groups: widget.groups,
                selection: _selection,
                onChanged: (selection) =>
                    setState(() => _selection = selection),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  Text('$count명 선택', style: AppText.listCaption),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: widget.buttonLabel,
                    enabled: widget.allowEmpty || count > 0,
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
