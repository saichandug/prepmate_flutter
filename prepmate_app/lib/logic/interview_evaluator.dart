// Port of src/utils/interviewEvaluator.js.
import 'dart:math';

class Evaluation {
  final int score;
  final List<String> matched;
  final bool strong;
  final List<String> strengths;
  final List<String> weaknesses;
  final String feedback;

  const Evaluation({
    required this.score,
    this.matched = const [],
    required this.strong,
    this.strengths = const [],
    this.weaknesses = const [],
    this.feedback = '',
  });
}

class AnswerEntry {
  final String questionId;
  final String question;
  final String answer;
  final List<String> concepts;
  final Evaluation evaluation;

  const AnswerEntry({
    required this.questionId,
    required this.question,
    required this.answer,
    required this.concepts,
    required this.evaluation,
  });
}

class InterviewResult {
  final int score;
  final int answered;
  final int strongCount;
  final int weakCount;
  final List<String> strengths;
  final List<String> weaknesses;

  const InterviewResult({
    required this.score,
    required this.answered,
    required this.strongCount,
    required this.weakCount,
    required this.strengths,
    required this.weaknesses,
  });
}

Evaluation evaluateAnswer(
  String? answer, [
  List<String> expectedConcepts = const [],
]) {
  final text = (answer ?? '').trim().toLowerCase();
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  final matched = expectedConcepts.where((concept) {
    final normalized = concept.toLowerCase();
    return normalized.isNotEmpty && text.contains(normalized);
  }).toList();

  // Random or irrelevant text must not earn points.
  if (text.isEmpty || matched.isEmpty) {
    return Evaluation(score: 0, matched: matched, strong: false);
  }

  // 80% of the score is concept coverage, up to 20% rewards a real explanation.
  final conceptScore = ((matched.length / max(expectedConcepts.length, 1)) * 80)
      .round();
  final lengthScore = min(20, ((words.length / 40) * 20).round());
  final score = min(100, conceptScore + lengthScore);

  return Evaluation(score: score, matched: matched, strong: score >= 70);
}

InterviewResult evaluateInterview(List<AnswerEntry> answers) {
  final total = answers.fold<int>(0, (sum, a) => sum + a.evaluation.score);
  final score = (total / max(answers.length, 1)).round();
  final strong = answers.where((a) => a.evaluation.strong).toList();
  final weak = answers.where((a) => !a.evaluation.strong).toList();

  final strengths = strong
      .expand((a) => a.concepts)
      .where((c) => strong.any((a) => a.evaluation.matched.contains(c)))
      .toSet()
      .take(4)
      .toList();
  final weaknesses = weak.expand((a) => a.concepts).toSet().take(4).toList();

  return InterviewResult(
    score: score,
    answered: answers.length,
    strongCount: strong.length,
    weakCount: weak.length,
    strengths: strengths.isNotEmpty
        ? strengths
        : ['Clear effort and structured responses'],
    weaknesses: weaknesses.isNotEmpty
        ? weaknesses
        : ['Add more concrete examples and key concepts'],
  );
}
