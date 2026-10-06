import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/flow.dart';
import '../providers/flow_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';

const _teal = Color(0xFF0F766E);
const _ink = Color(0xFF12343A);

class _DraftOption {
  final String id;
  final TextEditingController label;
  final TextEditingController detail;
  final TextEditingController issueText;
  String? nextStepId;
  bool recordsIssue;

  _DraftOption()
      : id = const Uuid().v4(),
        label = TextEditingController(text: 'Yes'),
        detail = TextEditingController(),
        issueText = TextEditingController(),
        recordsIssue = false;

  void dispose() {
    label.dispose();
    detail.dispose();
    issueText.dispose();
  }
}

class _DraftStep {
  final String id;
  final TextEditingController title;
  final TextEditingController body;
  bool requiresConfirm;
  final List<_DraftOption> options;

  _DraftStep()
      : id = const Uuid().v4(),
        title = TextEditingController(),
        body = TextEditingController(),
        requiresConfirm = false,
        options = [_DraftOption()];

  void dispose() {
    title.dispose();
    body.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _steps = [_DraftStep()];

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FtrScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: _ink)),
                Expanded(child: Text('New workflow', textAlign: TextAlign.center, style: AppTypography.title(size: 18, color: _ink))),
                TextButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  TextField(controller: _title, decoration: const InputDecoration(labelText: 'Workflow name')),
                  TextField(controller: _subtitle, decoration: const InputDecoration(labelText: 'Short description')),
                  const SizedBox(height: 16),
                  Text('Each answer can open a different next step.', style: AppTypography.body(size: 14, color: const Color(0xFF5C6F73))),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _steps.length; i++) _stepCard(i),
                  TextButton.icon(
                    onPressed: () => setState(() => _steps.add(_DraftStep())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add step'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard(int index) {
    final step = _steps[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step ${index + 1}', style: AppTypography.title(size: 14, color: _teal)),
          TextField(controller: step.title, decoration: const InputDecoration(labelText: 'Question')),
          TextField(controller: step.body, decoration: const InputDecoration(labelText: 'Guidance')),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: _teal,
            title: const Text('Require confirmation'),
            value: step.requiresConfirm,
            onChanged: (value) => setState(() => step.requiresConfirm = value),
          ),
          for (final option in step.options) _optionFields(step, option),
          TextButton(
            onPressed: () => setState(() {
              final extra = _DraftOption()..label.text = 'No';
              step.options.add(extra);
            }),
            child: const Text('Add answer'),
          ),
        ],
      ),
    );
  }

  Widget _optionFields(_DraftStep step, _DraftOption option) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          TextField(controller: option.label, decoration: const InputDecoration(labelText: 'Answer')),
          TextField(controller: option.detail, decoration: const InputDecoration(labelText: 'Detail')),
          DropdownButtonFormField<String?>(
            value: option.nextStepId,
            decoration: const InputDecoration(labelText: 'Leads to'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Finish')),
              for (final other in _steps)
                if (other.id != step.id)
                  DropdownMenuItem<String?>(value: other.id, child: Text(other.title.text.trim().isEmpty ? 'Untitled step' : other.title.text.trim())),
            ],
            onChanged: (value) => setState(() => option.nextStepId = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: _teal,
            title: const Text('Records an issue'),
            value: option.recordsIssue,
            onChanged: (value) => setState(() => option.recordsIssue = value),
          ),
          if (option.recordsIssue) TextField(controller: option.issueText, decoration: const InputDecoration(labelText: 'Issue note')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _title.text.trim();
    if (name.isEmpty || _steps.any((step) => step.title.text.trim().isEmpty || step.options.every((option) => option.label.text.trim().isEmpty))) {
      AppToast.show(context, title: 'Add a name and at least one answered step');
      return;
    }
    final playbook = Playbook(
      id: const Uuid().v4(),
      title: name,
      subtitle: _subtitle.text.trim().isEmpty ? 'Custom workflow' : _subtitle.text.trim(),
      steps: [
        for (final step in _steps)
          FlowStep(
            id: step.id,
            title: step.title.text.trim(),
            body: step.body.text.trim(),
            requiresConfirm: step.requiresConfirm,
            options: [
              for (final option in step.options)
                if (option.label.text.trim().isNotEmpty)
                  FlowOption(
                    id: option.id,
                    label: option.label.text.trim(),
                    detail: option.detail.text.trim(),
                    nextStepId: option.nextStepId,
                    recordsIssue: option.recordsIssue,
                    issueText: option.issueText.text.trim(),
                  ),
            ],
          ),
      ],
    );
    final saved = await context.read<FlowProvider>().create(playbook);
    if (!mounted) return;
    if (saved == null) {
      AppToast.show(context, title: 'Workflow limit reached');
      return;
    }
    Navigator.pop(context);
  }
}
