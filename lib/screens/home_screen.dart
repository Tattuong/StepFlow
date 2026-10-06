import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../models/flow.dart';
import '../providers/flow_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/coin_balance_chip.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import 'editor_screen.dart';
import 'report_screen.dart';
import 'run_screen.dart';

const _teal = Color(0xFF0F766E);
const _ink = Color(0xFF12343A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return FtrScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: _tab == 0 ? const _Library() : _tab == 1 ? const _History() : const _More()),
            if (_tab == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: _TealButton(label: 'New workflow', icon: Icons.add, onTap: () => _create(context)),
              ),
            const AdBannerSlot(),
            NavigationBar(
              selectedIndex: _tab,
              height: 64,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFD7F3EF),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) => setState(() => _tab = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Playbooks'),
                NavigationDestination(icon: Icon(Icons.history), label: 'History'),
                NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final flow = context.read<FlowProvider>();
    if (flow.custom.length >= context.read<ShopProvider>().maxArchive) {
      AppToast.show(context, title: AppStrings.t(context, 'needProFlows', {'n': '${context.read<ShopProvider>().maxArchive}'}));
      AppTabs.goShop();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen()));
  }
}

class _Library extends StatelessWidget {
  const _Library();

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<FlowProvider>();
    final active = flow.active;
    final book = active == null ? null : flow.findPlaybook(active.playbookId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      children: [
        const SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('StepFlow', style: TextStyle(fontFamily: AppTypography.outfitFamily, fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
              Row(
                children: [
                  CoinBalanceChip(variant: CoinChipVariant.header),
                  Spacer(),
                  IconButton(onPressed: AppTabs.goSettings, icon: Icon(Icons.settings_outlined, color: _ink)),
                ],
              ),
            ],
          ),
        ),
        Text('Your playbooks', style: AppTypography.display(size: 32, color: _ink).copyWith(height: 1.1, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Follow step-by-step workflows for everyday tasks.', style: AppTypography.body(size: 15, color: const Color(0xFF5C6F73))),
        if (active != null && book != null) ...[
          const SizedBox(height: 16),
          Text('Continue your session', style: AppTypography.title(size: 18, color: _ink)),
          const SizedBox(height: 8),
          _ResumeCard(session: active, playbook: book),
        ],
        const SizedBox(height: 16),
        for (final playbook in flow.playbooks) ...[
          _PlaybookTile(playbook: playbook),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PlaybookTile extends StatelessWidget {
  final Playbook playbook;

  const _PlaybookTile({required this.playbook});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final flow = context.read<FlowProvider>();
          final session = await flow.open(playbook);
          if (!context.mounted) return;
          await Navigator.push(context, MaterialPageRoute(builder: (_) => RunScreen(sessionId: session.id)));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: const Color(0xFFE7F6F3), borderRadius: BorderRadius.circular(12)),
                child: Icon(playbook.iconData, color: _teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(playbook.title, style: AppTypography.title(size: 16, color: _ink)),
                    const SizedBox(height: 2),
                    Text(playbook.subtitle, style: AppTypography.body(size: 13, color: const Color(0xFF5C6F73))),
                    const SizedBox(height: 4),
                    Text('${playbook.stepCount} steps', style: AppTypography.body(size: 12, color: const Color(0xFF8AA0A4))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8AA0A4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final FlowSession session;
  final Playbook playbook;

  const _ResumeCard({required this.session, required this.playbook});

  @override
  Widget build(BuildContext context) {
    final index = playbook.steps.indexWhere((step) => step.id == session.currentStepId);
    final stepNumber = index < 0 ? 1 : index + 1;
    final progress = playbook.stepCount == 0 ? 0.0 : stepNumber / playbook.stepCount;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RunScreen(sessionId: session.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(playbook.iconData, color: _teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(playbook.title, style: AppTypography.title(size: 16, color: _ink))),
                ],
              ),
              const SizedBox(height: 4),
              Text('Step $stepNumber of ${playbook.stepCount}', style: AppTypography.body(size: 13, color: const Color(0xFF5C6F73))),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: const Color(0xFFE4EEEC), color: _teal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History();

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<FlowProvider>().history;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text('History', style: AppTypography.display(size: 32, color: _ink).copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          Text('Finished and paused sessions show up here.', style: AppTypography.body(size: 15, color: const Color(0xFF5C6F73)))
        else
          for (final session in sessions) ...[
            Dismissible(
              key: ValueKey(session.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => context.read<FlowProvider>().discard(session.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Colors.white,
                title: Text(session.playbookTitle),
                subtitle: Text(session.done ? '${session.log.length} steps · ${session.issueCount} issues' : 'Paused · step in progress'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  final page = session.done ? ReportScreen(sessionId: session.id) : RunScreen(sessionId: session.id);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _More extends StatelessWidget {
  const _More();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text('More', style: AppTypography.display(size: 32, color: _ink).copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Branching checklists stay on this phone.', style: AppTypography.body(size: 15, color: const Color(0xFF5C6F73))),
        const SizedBox(height: 16),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: Colors.white,
          leading: const Icon(Icons.settings_outlined, color: _teal),
          title: const Text('Settings'),
          onTap: AppTabs.goSettings,
        ),
        const SizedBox(height: 10),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: Colors.white,
          leading: const Icon(Icons.storefront_outlined, color: _teal),
          title: const Text('Shop'),
          onTap: AppTabs.goShop,
        ),
      ],
    );
  }
}

class _TealButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TealButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: AppTypography.title(size: 16, color: Colors.white)),
    );
  }
}
