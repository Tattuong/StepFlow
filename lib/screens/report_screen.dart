import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/flow.dart';
import '../providers/flow_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_ui.dart';

const _teal = Color(0xFF0F766E);
const _ink = Color(0xFF12343A);

class ReportScreen extends StatelessWidget {
  final String sessionId;

  const ReportScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<FlowProvider>().findSession(sessionId);
    if (session == null) return const FtrScaffold(body: Center(child: Text('Session not found')));
    final issues = session.log.where((record) => record.issue).toList();
    final clock = DateFormat('HH:mm');
    return FtrScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                children: [
                  const Center(child: CircleAvatar(radius: 28, backgroundColor: Color(0xFFE7F6F3), child: Icon(Icons.check_rounded, color: _teal, size: 32))),
                  const SizedBox(height: 14),
                  Text('Session complete', textAlign: TextAlign.center, style: AppTypography.display(size: 30, color: _ink).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(session.playbookTitle, textAlign: TextAlign.center, style: AppTypography.body(size: 16, color: const Color(0xFF5C6F73))),
                  const SizedBox(height: 8),
                  Text(
                    '${session.log.length} of ${session.log.length} steps completed  |  ${issues.length} issue${issues.length == 1 ? '' : 's'} recorded',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(size: 13, color: const Color(0xFF8AA0A4)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFE7F6F3), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, color: _teal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('All done!', style: AppTypography.title(size: 16, color: _ink)),
                              Text('The workflow has been completed successfully.', style: AppTypography.body(size: 13, color: const Color(0xFF5C6F73))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final issue in issues) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Issue recorded', style: AppTypography.title(size: 15, color: _ink)),
                              Text(issue.issueText, style: AppTypography.body(size: 13, color: const Color(0xFF5C6F73))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Text('Completed steps', style: AppTypography.title(size: 16, color: _ink))),
                      Text('${session.log.length} / ${session.log.length}', style: AppTypography.body(size: 13, color: const Color(0xFF8AA0A4))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < session.log.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 12, backgroundColor: const Color(0xFFE7F6F3), child: Text('${i + 1}', style: const TextStyle(color: _teal, fontSize: 12))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(session.log[i].title, style: AppTypography.body(size: 15, color: _ink))),
                          Text(clock.format(session.log[i].at), style: AppTypography.body(size: 13, color: const Color(0xFF8AA0A4))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Share.share(_summary(session)),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text('Export summary'),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _summary(FlowSession session) {
    final clock = DateFormat('HH:mm');
    final issues = session.log.where((record) => record.issue).map((record) => '- ${record.issueText}').join('\n');
    final steps = [
      for (var i = 0; i < session.log.length; i++) '${i + 1}. ${session.log[i].title} — ${session.log[i].choice} — ${clock.format(session.log[i].at)}',
    ].join('\n');
    return 'StepFlow — ${session.playbookTitle}\n'
        '${session.log.length} steps completed, ${session.issueCount} issues\n\n'
        'Issues\n${issues.isEmpty ? '- None' : issues}\n\n'
        'Steps\n$steps';
  }
}
