import 'package:flutter/material.dart';

class FlowOption {
  final String id;
  final String label;
  final String detail;
  final String? nextStepId;
  final bool recordsIssue;
  final String issueText;

  const FlowOption({
    required this.id,
    required this.label,
    this.detail = '',
    this.nextStepId,
    this.recordsIssue = false,
    this.issueText = '',
  });

  FlowOption copyWith({String? label, String? detail, String? nextStepId, bool clearNext = false, bool? recordsIssue, String? issueText}) {
    return FlowOption(
      id: id,
      label: label ?? this.label,
      detail: detail ?? this.detail,
      nextStepId: clearNext ? null : (nextStepId ?? this.nextStepId),
      recordsIssue: recordsIssue ?? this.recordsIssue,
      issueText: issueText ?? this.issueText,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'detail': detail,
        'nextStepId': nextStepId,
        'recordsIssue': recordsIssue,
        'issueText': issueText,
      };

  factory FlowOption.fromJson(Map<String, dynamic> json) => FlowOption(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        nextStepId: json['nextStepId'] as String?,
        recordsIssue: json['recordsIssue'] as bool? ?? false,
        issueText: json['issueText'] as String? ?? '',
      );
}

class FlowStep {
  final String id;
  final String title;
  final String body;
  final bool requiresConfirm;
  final List<FlowOption> options;

  const FlowStep({
    required this.id,
    required this.title,
    this.body = '',
    this.requiresConfirm = false,
    this.options = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'requiresConfirm': requiresConfirm,
        'options': [for (final option in options) option.toJson()],
      };

  factory FlowStep.fromJson(Map<String, dynamic> json) => FlowStep(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        requiresConfirm: json['requiresConfirm'] as bool? ?? false,
        options: [
          for (final item in (json['options'] as List? ?? const []))
            FlowOption.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      );
}

class Playbook {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final bool builtIn;
  final List<FlowStep> steps;

  const Playbook({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.icon = 'list',
    this.builtIn = false,
    this.steps = const [],
  });

  int get stepCount => steps.length;

  FlowStep? stepById(String id) {
    for (final step in steps) {
      if (step.id == id) return step;
    }
    return null;
  }

  IconData get iconData => switch (icon) {
        'box' => Icons.inventory_2_outlined,
        'bed' => Icons.bed_outlined,
        'laptop' => Icons.laptop_mac_outlined,
        _ => Icons.account_tree_outlined,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
        'builtIn': builtIn,
        'steps': [for (final step in steps) step.toJson()],
      };

  factory Playbook.fromJson(Map<String, dynamic> json) => Playbook(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        icon: json['icon'] as String? ?? 'list',
        builtIn: json['builtIn'] as bool? ?? false,
        steps: [
          for (final item in (json['steps'] as List? ?? const [])) FlowStep.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      );
}

class StepRecord {
  final String stepId;
  final String title;
  final String choice;
  final bool issue;
  final String issueText;
  final DateTime at;

  const StepRecord({
    required this.stepId,
    required this.title,
    required this.choice,
    required this.issue,
    required this.issueText,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'stepId': stepId,
        'title': title,
        'choice': choice,
        'issue': issue,
        'issueText': issueText,
        'at': at.toIso8601String(),
      };

  factory StepRecord.fromJson(Map<String, dynamic> json) => StepRecord(
        stepId: json['stepId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        choice: json['choice'] as String? ?? '',
        issue: json['issue'] as bool? ?? false,
        issueText: json['issueText'] as String? ?? '',
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      );
}

class FlowSession {
  final String id;
  final String playbookId;
  final String playbookTitle;
  String currentStepId;
  bool done;
  bool rewarded;
  final List<StepRecord> log;
  DateTime updatedAt;

  FlowSession({
    required this.id,
    required this.playbookId,
    required this.playbookTitle,
    required this.currentStepId,
    this.done = false,
    this.rewarded = false,
    List<StepRecord>? log,
    DateTime? updatedAt,
  })  : log = log ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  int get issueCount => log.where((record) => record.issue).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'playbookId': playbookId,
        'playbookTitle': playbookTitle,
        'currentStepId': currentStepId,
        'done': done,
        'rewarded': rewarded,
        'log': [for (final record in log) record.toJson()],
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FlowSession.fromJson(Map<String, dynamic> json) => FlowSession(
        id: json['id'] as String? ?? '',
        playbookId: json['playbookId'] as String? ?? '',
        playbookTitle: json['playbookTitle'] as String? ?? '',
        currentStepId: json['currentStepId'] as String? ?? '',
        done: json['done'] as bool? ?? false,
        rewarded: json['rewarded'] as bool? ?? false,
        log: [
          for (final item in (json['log'] as List? ?? const [])) StepRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
