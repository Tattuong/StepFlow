import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/shop_item.dart';
import '../providers/shop_provider.dart';

import '../models/flow.dart';
import '../providers/flow_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import 'report_screen.dart';

const _teal = Color(0xFF0F766E);
const _ink = Color(0xFF12343A);
const _no = Color(0xFFE11D48);

class RunScreen extends StatefulWidget {
  final String sessionId;

  const RunScreen({super.key, required this.sessionId});

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  var _confirmed = false;
  String? _confirmedStep;
  var _awake = false;

  @override
  void initState() {
    super.initState();
    if (context.read<ShopProvider>().featureOn(ShopCatalog.featAwake)) {
      _awake = true;
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    if (_awake) WakelockPlus.disable();
    super.dispose();
  }

  bool _ready(FlowStep step) => _confirmedStep == step.id ? _confirmed : !step.requiresConfirm;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<FlowProvider>();
    final session = flow.findSession(widget.sessionId);
    final playbook = session == null ? null : flow.findPlaybook(session.playbookId);
    if (session == null || playbook == null) {
      return const FtrScaffold(body: Center(child: Text('Session not found')));
    }
    if (session.done) {
      return ReportScreen(sessionId: session.id);
    }
    final step = playbook.stepById(session.currentStepId) ?? playbook.steps.first;
    final ready = _ready(step);
    final index = playbook.steps.indexWhere((item) => item.id == step.id);
    final number = index < 0 ? 1 : index + 1;
    final progress = playbook.stepCount == 0 ? 0.0 : number / playbook.stepCount;
    return FtrScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded, color: _ink),
                    label: const Text('Back', style: TextStyle(color: _ink)),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Exit session')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: const Color(0xFFE4EEEC), color: _teal),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Text('Step $number of ${playbook.stepCount}', style: AppTypography.body(size: 14, color: _teal)),
                  const SizedBox(height: 8),
                  Text(step.title, style: AppTypography.display(size: 30, color: _ink).copyWith(fontWeight: FontWeight.w700, height: 1.15)),
                  const SizedBox(height: 8),
                  Text(step.body, style: AppTypography.body(size: 16, color: const Color(0xFF5C6F73))),
                  if (step.requiresConfirm) ...[
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: ready,
                      contentPadding: EdgeInsets.zero,
                      activeColor: _teal,
                      title: const Text('I confirm this check'),
                      onChanged: (value) => setState(() {
                        _confirmedStep = step.id;
                        _confirmed = value ?? false;
                      }),
                    ),
                  ],
                  const SizedBox(height: 12),
                  for (final option in step.options) ...[
                    _ChoiceCard(
                      option: option,
                      enabled: ready,
                      onTap: () {
                        if (!ready) {
                          AppToast.show(context, title: 'Confirm this check before you continue');
                          return;
                        }
                        _choose(context, option);
                      },
                    ),
                    if (option.recordsIssue)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.turn_right_rounded, size: 16, color: Color(0xFF8AA0A4)),
                            const SizedBox(width: 6),
                            Text('${option.label} → Record issue', style: AppTypography.body(size: 13, color: const Color(0xFF8AA0A4))),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: OutlinedButton.icon(
                onPressed: session.log.isEmpty ? null : () => context.read<FlowProvider>().backStep(session.id),
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(BuildContext context, FlowOption option) async {
    if (context.read<ShopProvider>().featureOn(ShopCatalog.featSound)) {
      SystemSound.play(SystemSoundType.click);
    }
    final done = await context.read<FlowProvider>().answer(widget.sessionId, option);
    if (!context.mounted || !done) return;
    await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReportScreen(sessionId: widget.sessionId)));
  }
}

class _ChoiceCard extends StatelessWidget {
  final FlowOption option;
  final bool enabled;
  final VoidCallback onTap;

  const _ChoiceCard({required this.option, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final issue = option.recordsIssue;
    final color = issue ? _no : _teal;
    final fill = issue ? const Color(0xFFFDECEC) : const Color(0xFFE7F6F3);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Icon(issue ? Icons.close_rounded : Icons.check_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.label, style: AppTypography.title(size: 16, color: _ink)),
                      if (option.detail.isNotEmpty) Text(option.detail, style: AppTypography.body(size: 13, color: const Color(0xFF5C6F73))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
