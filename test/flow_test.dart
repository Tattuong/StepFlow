import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stepflow/core/constants/iap_constants.dart';
import 'package:stepflow/core/services/hive_service.dart';
import 'package:stepflow/core/services/storage_service.dart';
import 'package:stepflow/models/flow.dart';
import 'package:stepflow/models/playbook_catalog.dart';
import 'package:stepflow/providers/flow_provider.dart';
import 'package:stepflow/providers/shop_provider.dart';
import 'package:stepflow/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('sf_flow');
    await HiveService.init(path: dir.path, suffix: '_flow');
    await StorageService.instance.init();
  });

  setUp(() async {
    await HiveService.kv.clear();
  });

  test('No on intact records the box issue and the session resumes', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final flow = FlowProvider(shop);
    await flow.init();
    final books = PlaybookCatalog.builtIns();
    expect(books.map((book) => book.stepCount), [6, 8, 7]);
    final pack = books.first;
    final session = await flow.start(pack);
    expect(pack.stepById(session.currentStepId)!.requiresConfirm, isTrue);
    await flow.answer(session.id, pack.stepById('p1')!.options.first);
    await flow.answer(session.id, pack.stepById('p2')!.options.first);
    expect(flow.findSession(session.id)!.currentStepId, 'p3');
    final no = pack.stepById('p3')!.options.firstWhere((option) => option.label == 'No');
    expect(await flow.answer(session.id, no), isFalse);
    final saved = flow.findSession(session.id)!;
    expect(saved.currentStepId, 'p4');
    expect(saved.issueCount, 1);
    expect(saved.log.last.issueText, 'Box replaced before dispatch');
    await flow.backStep(session.id);
    expect(flow.findSession(session.id)!.currentStepId, 'p3');
    expect(flow.findSession(session.id)!.done, isFalse);

    final again = FlowProvider(shop);
    await again.init();
    expect(again.findSession(session.id)!.currentStepId, 'p3');
    expect(again.active?.id, session.id);
  });

  test('finishing a workflow adds coins once', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final flow = FlowProvider(shop);
    await flow.init();
    final book = _book('pay');
    expect(await flow.create(book), isNotNull);
    final session = await flow.start(book);
    expect(await flow.answer(session.id, book.steps.first.options.first), isTrue);
    expect(shop.coins, IapConstants.testCompleteReward);
    expect(flow.findSession(session.id)!.rewarded, isTrue);
    await flow.backStep(session.id);
    expect(await flow.answer(session.id, book.steps.first.options.first), isTrue);
    expect(shop.coins, IapConstants.testCompleteReward);
  });

  test('a free account stops at eight custom workflows', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final flow = FlowProvider(shop);
    await flow.init();
    for (var i = 0; i < 8; i++) {
      final saved = await flow.create(_book('w$i'));
      expect(saved, isNotNull);
    }
    expect(await flow.create(_book('w9')), isNull);
    expect(flow.custom, hasLength(8));
    expect(flow.playbooks, hasLength(11));
  });

  testWidgets('playbook library opens', (tester) async {
    late ShopProvider shop;
    late FlowProvider flow;
    await tester.runAsync(() async {
      shop = ShopProvider();
      await shop.init(remote: false);
      flow = FlowProvider(shop);
      await flow.init();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: shop),
          ChangeNotifierProvider.value(value: flow),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Your playbooks'), findsOneWidget);
    expect(find.text('Pack an order'), findsOneWidget);
    expect(find.text('New workflow'), findsOneWidget);
  });

  test('opening a playbook again resumes the paused session', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final flow = FlowProvider(shop);
    await flow.init();
    final book = PlaybookCatalog.builtIns().first;
    final first = await flow.open(book);
    final second = await flow.open(book);
    expect(second.id, first.id);
    expect(flow.sessions.where((session) => session.playbookId == book.id), hasLength(1));
  });
}

Playbook _book(String id) => Playbook(
      id: id,
      title: id,
      steps: [
        FlowStep(
          id: '$id-s',
          title: 'Ready?',
          options: [FlowOption(id: '$id-o', label: 'Yes')],
        ),
      ],
    );
