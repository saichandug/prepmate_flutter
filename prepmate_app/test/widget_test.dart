// Logic tests. Run with:  flutter test
// (tool/parity_check.dart additionally compares these ports with the original JS.)
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_app/logic/interview_evaluator.dart';
import 'package:prepmate_app/logic/jd_analyzer.dart';
import 'package:prepmate_app/logic/streak_manager.dart';
import 'package:prepmate_app/logic/validation.dart';

void main() {
  test('company and role validation', () {
    expect(validateCompanyName('Amazon'), '');
    expect(validateCompanyName('asdfgh'), isNotEmpty);
    expect(validateJobRole('Software Engineer'), '');
    expect(validateJobRole('sdfdsg'), isNotEmpty);
  });

  test('job description analyzer', () {
    final result = analyzeJD(
      'We are looking for a Software Engineer with strong Java, SQL and data structures knowledge. Responsibilities include building REST API services.',
    );
    expect(result['status'], 'success');
    expect(result['keywords'], containsAll(['Java', 'SQL']));
    expect(analyzeJD('short')['status'], 'short');
  });

  test('random text earns no points', () {
    expect(evaluateAnswer('asdf qwer', ['O(n)', 'single pass']).score, 0);
    expect(
      evaluateAnswer('single pass, O(n) time', ['O(n)', 'single pass']).score,
      greaterThan(0),
    );
  });

  test('streak needs three activities in a day', () {
    final day = DateTime.utc(2026, 10, 20, 10);
    var s = emptyStreak();
    s = recordActivity(s, 'roadmap', now: day);
    s = recordActivity(s, 'coding', now: day);
    expect(s['current'], 0);
    s = recordActivity(s, 'mock', now: day);
    expect(s['current'], 1);
  });
}
