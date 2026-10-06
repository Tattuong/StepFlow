import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/services/storage_service.dart';
import '../models/flow.dart';
import '../models/playbook_catalog.dart';
import 'shop_provider.dart';

class FlowProvider extends ChangeNotifier {
  static const _playbooksKey = 'sf_playbooks';
  static const _sessionsKey = 'sf_sessions';

  final ShopProvider shop;
  final List<Playbook> custom = [];
  final List<FlowSession> sessions = [];

  FlowProvider(this.shop);

  List<Playbook> get playbooks => [...PlaybookCatalog.builtIns(), ...custom];

  FlowSession? get active {
    final open = sessions.where((session) => !session.done).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return open.isEmpty ? null : open.first;
  }

  List<FlowSession> get history {
    final copy = [...sessions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return copy;
  }

  Playbook? findPlaybook(String id) {
    for (final playbook in playbooks) {
      if (playbook.id == id) return playbook;
    }
    return null;
  }

  FlowSession? findSession(String id) {
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  Future<void> init() async {
    custom.clear();
    sessions.clear();
    final rawBooks = await StorageService.instance.getString(_playbooksKey);
    if (rawBooks != null && rawBooks.isNotEmpty) {
      final list = jsonDecode(rawBooks) as List;
      custom.addAll(list.map((item) => Playbook.fromJson(Map<String, dynamic>.from(item as Map))));
    }
    final rawSessions = await StorageService.instance.getString(_sessionsKey);
    if (rawSessions != null && rawSessions.isNotEmpty) {
      final list = jsonDecode(rawSessions) as List;
      sessions.addAll(list.map((item) => FlowSession.fromJson(Map<String, dynamic>.from(item as Map))));
    }
    notifyListeners();
  }

  Future<Playbook?> create(Playbook playbook) async {
    if (custom.length >= shop.maxArchive) return null;
    custom.insert(0, playbook);
    await _saveBooks();
    notifyListeners();
    return playbook;
  }

  Future<void> deletePlaybook(String id) async {
    custom.removeWhere((playbook) => playbook.id == id && !playbook.builtIn);
    await _saveBooks();
    notifyListeners();
  }

  FlowSession? unfinishedFor(String playbookId) {
    FlowSession? latest;
    for (final session in sessions) {
      if (session.done || session.playbookId != playbookId) continue;
      if (latest == null || session.updatedAt.isAfter(latest.updatedAt)) latest = session;
    }
    return latest;
  }

  Future<FlowSession> open(Playbook playbook) async {
    return unfinishedFor(playbook.id) ?? start(playbook);
  }

  Future<FlowSession> start(Playbook playbook) async {
    final session = FlowSession(
      id: const Uuid().v4(),
      playbookId: playbook.id,
      playbookTitle: playbook.title,
      currentStepId: playbook.steps.first.id,
    );
    sessions.insert(0, session);
    await _saveSessions();
    notifyListeners();
    return session;
  }

  Future<bool> answer(String sessionId, FlowOption option) async {
    final session = findSession(sessionId);
    final playbook = session == null ? null : findPlaybook(session.playbookId);
    final step = playbook?.stepById(session!.currentStepId);
    if (session == null || playbook == null || step == null) return false;
    session.log.add(
      StepRecord(
        stepId: step.id,
        title: step.title,
        choice: option.label,
        issue: option.recordsIssue,
        issueText: option.recordsIssue ? (option.issueText.isEmpty ? option.label : option.issueText) : '',
        at: DateTime.now(),
      ),
    );
    final wasDone = session.done;
    final next = option.nextStepId;
    if (next == null || playbook.stepById(next) == null) {
      session.done = true;
    } else {
      session.currentStepId = next;
    }
    if (session.done && !wasDone && !session.rewarded) {
      session.rewarded = true;
      await shop.rewardForWorkflow();
    }
    session.updatedAt = DateTime.now();
    await _saveSessions();
    notifyListeners();
    return session.done;
  }

  Future<void> discard(String sessionId) async {
    sessions.removeWhere((session) => session.id == sessionId);
    await _saveSessions();
    notifyListeners();
  }

  Future<void> backStep(String sessionId) async {
    final session = findSession(sessionId);
    if (session == null || session.log.isEmpty) return;
    final last = session.log.removeLast();
    session.done = false;
    session.currentStepId = last.stepId;
    session.updatedAt = DateTime.now();
    await _saveSessions();
    notifyListeners();
  }

  Future<void> _saveBooks() async {
    await StorageService.instance.saveString(_playbooksKey, jsonEncode([for (final book in custom) book.toJson()]));
  }

  Future<void> _saveSessions() async {
    await StorageService.instance.saveString(_sessionsKey, jsonEncode([for (final session in sessions) session.toJson()]));
  }
}
