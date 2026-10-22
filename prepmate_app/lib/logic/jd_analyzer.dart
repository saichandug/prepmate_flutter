// Port of src/utils/jdAnalyzer.js. The result is a JSON-compatible map so it can
// be saved to the server exactly like the React app did.
import '../data/skills.dart';

bool _containsAlias(String text, String alias) {
  if (alias.length <= 2) {
    final pattern = RegExp(
      '(^|[^a-z0-9+#])${RegExp.escape(alias.trim())}([^a-z0-9+#]|\$)',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }
  return text.contains(alias.toLowerCase());
}

Map<String, dynamic> analyzeJD(Object? input) {
  final text = (input ?? '').toString().trim();
  if (text.isEmpty)
    return {'status': 'empty', 'message': 'Job description is required.'};
  if (text.length < 30)
    return {'status': 'short', 'message': 'Job Description Too Short'};

  final normalized = text.toLowerCase();
  final detected = skillDictionary
      .where((skill) => skill.aliases.any((a) => _containsAlias(normalized, a)))
      .toList();

  if (detected.isEmpty) {
    return {
      'status': 'unrelated',
      'message': 'The entered text does not appear to contain software-job requirements. Please enter a relevant job description containing skills, responsibilities, or requirements.',
      'skills': <Map<String, dynamic>>[],
    };
  }

  final skills = detected
      .map(
        (s) => <String, dynamic>{
          'name': s.name,
          'category': s.category,
          'aliases': s.aliases,
          'priority': priorityByCategory[s.category] ?? 'LOW',
        },
      )
      .toList();

  return {
    'status': skills.length <= 2 ? 'limited' : 'success',
    'skills': skills,
    'categories': skills.map((s) => s['category']).toSet().toList(),
    'keywords': skills.map((s) => s['name']).toList(),
  };
}
