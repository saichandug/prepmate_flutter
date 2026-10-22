// Differential test: compares the Dart ports against output produced by the
// original JavaScript functions (tool/parity_cases.json).
// Run from the project folder:  dart run tool/parity_check.dart
import 'dart:convert';
import 'dart:io';

import '../lib/data/questions.dart';
import '../lib/logic/interview_evaluator.dart';
import '../lib/logic/jd_analyzer.dart';
import '../lib/logic/roadmap_generator.dart';
import '../lib/logic/streak_manager.dart';
import '../lib/logic/validation.dart';

int failures = 0;
int checks = 0;

void expectEq(String label, Object? actual, Object? expected) {
  checks++;
  final a = jsonEncode(actual);
  final e = jsonEncode(expected);
  if (a != e) {
    failures++;
    if (failures <= 15)
      stdout.writeln('MISMATCH $label\n  dart: $a\n  js:   $e');
  }
}

String short(String s) => s.substring(0, s.length < 25 ? s.length : 25);

void main() {
  final data = jsonDecode(
    File('tool/parity_cases.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final c in data['validateCompany']) {
    expectEq('company "${c[0]}"', validateCompanyName(c[0]), c[1]);
  }
  for (final c in data['validateRole']) {
    expectEq('role "${c[0]}"', validateJobRole(c[0]), c[1]);
  }
  for (final c in data['validateJD']) {
    expectEq('jd "${short(c[0])}"', validateJD(c[0]), c[1]);
  }
  for (final c in data['analyze']) {
    final r = analyzeJD(c[0]);
    final skills = ((r['skills'] ?? []) as List)
        .map((s) => [s['name'], s['priority'], s['category']])
        .toList();
    final actual = {
      'status': r['status'],
      'skills': skills,
      'categories': r['categories'],
      'keywords': r['keywords'],
      'message': r['message'],
    };
    expectEq('analyze "${short(c[0])}"', actual, c[1]);
  }
  for (final c in data['validateApp']) {
    expectEq(
      'validateApplication ${jsonEncode(c[0])}',
      validateApplication(Map<String, dynamic>.from(c[0])),
      c[1],
    );
  }
  for (final c in data['evalAnswer']) {
    final e = evaluateAnswer(c[0], List<String>.from(c[1]));
    expectEq('evaluateAnswer "${c[0]}" ${c[1]}', {
      'score': e.score,
      'matched': e.matched,
      'strong': e.strong,
    }, c[2]);
  }

  final entries = (data['interview']['entries'] as List).map((e) {
    final concepts = List<String>.from(e['concepts']);
    return AnswerEntry(
      questionId: e['questionId'],
      question: e['question'],
      answer: e['answer'],
      concepts: concepts,
      evaluation: evaluateAnswer(e['answer'], concepts),
    );
  }).toList();
  final r = evaluateInterview(entries);
  expectEq('evaluateInterview', {
    'score': r.score,
    'answered': r.answered,
    'strongCount': r.strongCount,
    'weakCount': r.weakCount,
    'strengths': r.strengths,
    'weaknesses': r.weaknesses,
  }, data['interview']['result']);

  final now = DateTime.fromMillisecondsSinceEpoch(data['nowMs'], isUtc: true);
  for (final c in data['roadmap']) {
    final input = c[0] as Map<String, dynamic>;
    final actual = generateRoadmap(
      company: input['company'],
      role: input['role'],
      experience: input['experience'],
      interviewDate: input['interviewDate'],
      preparationHours: input['preparationHours'],
      skills: (input['skills'] as List)
          .map((s) => Map<String, dynamic>.from(s))
          .toList(),
      now: now,
    );
    expectEq(
      'roadmap ${input['interviewDate']} ${input['preparationHours']}',
      actual,
      c[1],
    );
  }

  var s = emptyStreak();
  for (final step in data['streakSteps']) {
    final at = DateTime.parse(step[0]);
    s = recordActivity(s, step[1], now: at);
    expectEq('streak ${step[0]} ${step[1]}', s, step[2]);
    expectEq('today ${step[0]}', getTodayActivities(s, now: at), step[3]);
  }

  stdout.writeln('questions in Dart bank: ${questions.length}');
  stdout.writeln('$checks checks, $failures mismatches');
  exit(failures == 0 ? 0 : 1);
}
