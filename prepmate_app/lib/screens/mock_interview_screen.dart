import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/questions.dart';
import '../logic/interview_evaluator.dart';
import '../models/question.dart';
import '../providers/workspace_controller.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _knownCompanies = {
  'amazon',
  'google',
  'microsoft',
  'apple',
  'meta',
  'netflix',
  'adobe',
  'ibm',
  'oracle',
  'salesforce',
  'intel',
  'nvidia',
  'accenture',
  'tcs',
  'infosys',
  'wipro',
  'hcl',
  'capgemini',
  'cognizant',
  'deloitte',
  'ey',
  'pwc',
  'kpmg',
  'zoho',
  'paypal',
  'uber',
  'airbnb',
  'linkedin',
  'openai',
  'flipkart',
  'swiggy',
  'zomato',
  'ola',
  'qualcomm',
  'cisco',
};

final _companySuffixes = RegExp(
  r'\b(inc|incorporated|llc|ltd|limited|corp|corporation|technologies|technology|solutions|systems|software|labs|group|services|industries|pvt|private)\b',
  caseSensitive: false,
);
final _roleTerms = RegExp(
  r'\b(engineer|developer|analyst|designer|manager|scientist|intern|consultant|architect|administrator|tester|qa|devops|data|software|web|frontend|backend|full[- ]?stack|product|security|cloud|machine learning|ai|database|technical|business)\b',
  caseSensitive: false,
);
final _nameChars = RegExp(r"^[A-Za-z0-9&.,'()\-\s]+$");

bool _validCompanyName(String value) {
  final text = value.trim();
  if (text.length < 2 || text.length > 100) return false;
  if (!_nameChars.hasMatch(text)) return false;
  final compact = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (_knownCompanies.contains(compact)) return true;
  if (_companySuffixes.hasMatch(text)) return true;
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return words.length >= 2 &&
      words.every((w) => RegExp(r'[A-Za-z]{2,}').hasMatch(w));
}

bool _validRole(String value) {
  final text = value.trim();
  if (text.length < 2 || text.length > 120) return false;
  if (!_nameChars.hasMatch(text)) return false;
  return _roleTerms.hasMatch(text);
}

Question _normalizeQuestion(Map<String, dynamic> item, int index) {
  final topic = (item['topic'] ?? '').toString();
  final concepts = item['concepts'] is List
      ? (item['concepts'] as List).map((c) => c.toString()).toList()
      : <String>[];
  return Question(
    id: (item['id'] ?? 'ai-${DateTime.now().millisecondsSinceEpoch}-$index')
        .toString(),
    company: (item['company'] ?? 'AI Generated').toString(),
    topic: topic.isEmpty ? 'Technical Interview' : topic,
    difficulty: (item['difficulty'] ?? 'Medium').toString(),
    question: (item['question'] ?? '').toString(),
    concepts: concepts.isNotEmpty
        ? concepts
        : [topic.isEmpty ? 'core concept' : topic],
  );
}

enum _Stage { setup, running, result }

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  final _company = TextEditingController();
  final _role = TextEditingController();
  final _answer = TextEditingController();

  _Stage _stage = _Stage.setup;
  String _difficulty = 'Medium';
  List<Question> _session = [];
  List<AnswerEntry> _answers = [];
  int _index = 0;
  Evaluation? _submitted;
  InterviewResult? _result;
  bool _busy = false;
  bool _aiUsed = false;

  @override
  void dispose() {
    _company.dispose();
    _role.dispose();
    _answer.dispose();
    super.dispose();
  }

  void _warn(String message) => showToast(context, message, ToastKind.warning);

  List<Question> _pickFallbackSession() {
    final wantedCompany = _company.text.trim().toLowerCase();
    final roleWords = _role.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final companyPool = wantedCompany.isEmpty
        ? <Question>[]
        : questions
              .where((q) => q.company.toLowerCase() == wantedCompany)
              .toList();
    final rolePool = questions.where((q) {
      final haystack = '${q.topic} ${q.question}'.toLowerCase();
      return roleWords.any(haystack.contains);
    }).toList();
    final difficultyPool = questions
        .where((q) => _difficulty == 'All' || q.difficulty == _difficulty)
        .toList();
    final source = [
      ...companyPool,
      ...rolePool,
      ...difficultyPool,
      ...questions,
    ]..shuffle(Random());
    final unique = <Question>[];
    for (final item in source) {
      if (!unique.any((q) => q.id == item.id)) unique.add(item);
    }
    return unique.take(min(10, max(5, unique.length))).toList();
  }

  Future<void> _start() async {
    final company = _company.text;
    final role = _role.text;
    if (company.trim().isEmpty) return _warn('Company name is required.');
    if (!_validCompanyName(company)) {
      return _warn(
        'Enter a valid company/organization name, such as Google, Amazon, OpenAI, or Acme Technologies.',
      );
    }
    if (role.trim().isEmpty) return _warn('Job role is required.');
    if (!_validRole(role)) {
      return _warn(
        'Enter a valid job role, such as Software Engineer, Data Analyst, or Frontend Developer.',
      );
    }

    setState(() => _busy = true);
    final api = context.read<ApiClient>();
    List<Question> session;
    bool ai = false;
    try {
      final res = await api.gemini('questions', {
        'company': company.trim(),
        'role': role.trim(),
        'difficulty': _difficulty,
      });
      final generated = ((res['questions'] as List?) ?? [])
          .whereType<Map>()
          .where((q) => (q['question'] ?? '').toString().isNotEmpty)
          .toList()
          .asMap()
          .entries
          .map(
            (e) =>
                _normalizeQuestion(Map<String, dynamic>.from(e.value), e.key),
          )
          .toList();
      if (generated.length < 5)
        throw const ApiException('Not enough AI questions returned.');
      session = generated.take(10).toList();
      ai = true;
      if (mounted)
        showToast(
          context,
          'Gemini generated a fresh interview set for this role.',
          ToastKind.success,
        );
    } catch (error) {
      session = _pickFallbackSession();
      final reason = error is ApiException ? error.message : 'request failed';
      if (mounted)
        _warn(
          "Gemini unavailable: $reason Using PrepMate's varied question bank instead.",
        );
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _aiUsed = ai;
      _answers = [];
      _index = 0;
      _answer.clear();
      _submitted = null;
      _result = null;
      _stage = _Stage.running;
      _busy = false;
    });
  }

  Future<void> _submit() async {
    if (_submitted != null || _busy) return;
    final text = _answer.text.trim();
    if (text.isEmpty) return _warn('Please enter an answer before continuing.');

    setState(() => _busy = true);
    final current = _session[_index];
    Evaluation evaluation;
    try {
      final ai = await context.read<ApiClient>().gemini('evaluate', {
        'question': current.question,
        'answer': text,
        'concepts': current.concepts,
      });
      final raw = ai['score'] is num
          ? (ai['score'] as num).toDouble()
          : double.tryParse('${ai['score']}') ?? 0;
      List<String> strings(Object? v) =>
          v is List ? v.map((e) => e.toString()).toList() : <String>[];
      evaluation = Evaluation(
        score: raw.clamp(0, 100).round(),
        matched: strings(ai['matchedConcepts']),
        strong: raw >= 70,
        strengths: strings(ai['strengths']),
        weaknesses: strings(ai['weaknesses']),
        feedback: (ai['feedback'] ?? '').toString(),
      );
      _aiUsed = true;
    } catch (_) {
      evaluation = evaluateAnswer(text, current.concepts);
      if (mounted)
        _warn(
          'AI evaluation unavailable; using rule-based scoring for this answer.',
        );
    }
    if (!mounted) return;
    setState(() {
      _submitted = evaluation;
      _busy = false;
    });
  }

  void _next() {
    final submitted = _submitted;
    if (submitted == null)
      return _warn('Submit your answer before continuing.');

    final current = _session[_index];
    final all = [
      ..._answers,
      AnswerEntry(
        questionId: current.id,
        question: current.question,
        answer: _answer.text,
        concepts: current.concepts,
        evaluation: submitted,
      ),
    ];

    if (_index == _session.length - 1) {
      final evaluated = evaluateInterview(all);
      final aiStrengths = all
          .expand((a) => a.evaluation.strengths)
          .where((s) => s.isNotEmpty)
          .toSet()
          .take(4)
          .toList();
      final aiWeaknesses = all
          .expand((a) => a.evaluation.weaknesses)
          .where((s) => s.isNotEmpty)
          .toSet()
          .take(4)
          .toList();
      final strengths = aiStrengths.isNotEmpty
          ? aiStrengths
          : evaluated.strengths;
      final weaknesses = aiWeaknesses.isNotEmpty
          ? aiWeaknesses
          : evaluated.weaknesses;
      final finalResult = InterviewResult(
        score: evaluated.score,
        answered: evaluated.answered,
        strongCount: evaluated.strongCount,
        weakCount: evaluated.weakCount,
        strengths: strengths,
        weaknesses: weaknesses,
      );
      final now = DateTime.now();
      context.read<WorkspaceController>().finishMock({
        'id': '${now.microsecondsSinceEpoch}',
        'date': now.toUtc().toIso8601String(),
        'company': _company.text.trim(),
        'role': _role.text.trim(),
        'score': finalResult.score,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'aiPowered': _aiUsed,
      });
      setState(() {
        _result = finalResult;
        _stage = _Stage.result;
      });
      return;
    }
    setState(() {
      _answers = all;
      _index++;
      _answer.clear();
      _submitted = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.setup:
        return _setup();
      case _Stage.result:
        return _resultView();
      case _Stage.running:
        return _question();
    }
  }

  // ------------------------------------------------------------------ setup
  Widget _setup() {
    final history = context.watch<WorkspaceController>().mockHistory;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF171125), Color(0xFF36216B)],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gemini AI interview',
                style: TextStyle(
                  color: Color(0xFFA78BFA),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Practice under real interview pressure.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter any company and role. Gemini creates a fresh, varied interview set and evaluates each answer. If AI is unavailable, PrepMate automatically falls back to its built-in question bank and scoring.',
                style: TextStyle(color: Color(0xFFC9C1DC), height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _company,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Company *',
                  hintText: 'e.g. Google, Microsoft, Startup ABC',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _role,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Role *',
                  hintText: 'e.g. Software Engineer',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              LabeledDropdown<String>(
                label: 'Difficulty',
                value: _difficulty,
                items: const ['Easy', 'Medium', 'Hard', 'All'],
                onChanged: (v) => setState(() => _difficulty = v),
              ),
              const SizedBox(height: 14),
              const InlineAlert(
                'Questions are generated from the company and role context, but are not claimed to be official company interview questions.',
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _busy ? null : _start,
                child: Text(
                  _busy
                      ? 'Creating AI Interview...'
                      : 'Start AI Mock Interview',
                ),
              ),
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  eyebrow: 'Previous attempts',
                  title: 'Mock interview history',
                ),
                const SizedBox(height: 8),
                for (final item in history.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['company']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${item['role']} · ${_historyDate(item['date'])}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item['score']}/100',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _historyDate(Object? value) {
    final d = DateTime.tryParse((value ?? '').toString())?.toLocal();
    return d == null ? '' : '${d.day} ${monthShort(d)} ${d.year}';
  }

  // --------------------------------------------------------------- question
  Widget _question() {
    final current = _session[_index];
    final submitted = _submitted;
    final (bg, fg) = difficultyColors(current.difficulty);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Question ${_index + 1} of ${_session.length}',
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ProgressBar(
          value: (_index + 1) / _session.length * 100,
          showValue: false,
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TagChip(_company.text.trim()),
                  Pill(current.difficulty, background: bg, foreground: fg),
                  Text(
                    current.topic,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                current.question,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _answer,
                minLines: 7,
                maxLines: 12,
                enabled: submitted == null,
                decoration: const InputDecoration(
                  labelText: 'Your Answer',
                  hintText: 'Explain your approach clearly. Include examples and important concepts...',
                  alignLabelWithHint: true,
                ),
              ),
              if (submitted != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: submitted.strong
                        ? AppColors.greenSoft
                        : AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_aiUsed ? 'Gemini score' : 'Rule-based score'}: ${submitted.score}/100',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: submitted.strong
                              ? AppColors.green
                              : AppColors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matched concepts: ${submitted.matched.isEmpty ? 'None yet' : submitted.matched.join(', ')}',
                      ),
                      if (submitted.feedback.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(submitted.feedback),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: (submitted != null || _busy) ? null : _submit,
                      child: Text(_busy ? 'Evaluating...' : 'Submit Answer'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _next,
                      child: Text(
                        _index == _session.length - 1
                            ? 'Finish'
                            : 'Next Question',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- result
  Widget _resultView() {
    final r = _result!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF171125), Color(0xFF36216B)],
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Interview readiness',
                style: TextStyle(
                  color: Color(0xFFA78BFA),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  text: '${r.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                  ),
                  children: const [
                    TextSpan(
                      text: '/100',
                      style: TextStyle(fontSize: 18, color: Color(0xFFC9C1DC)),
                    ),
                  ],
                ),
              ),
              Text(
                _aiUsed
                    ? 'Gemini-assisted interview evaluation'
                    : 'PrepMate rule-based interview evaluation',
                style: const TextStyle(color: Color(0xFFC9C1DC)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 24) / 3;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: w, child: _count('${r.answered}', 'Answered')),
                SizedBox(width: w, child: _count('${r.strongCount}', 'Strong')),
                SizedBox(
                  width: w,
                  child: _count('${r.weakCount}', 'To improve'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Strengths',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              for (final s in r.strengths)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '✓ $s',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              const SizedBox(height: 14),
              const Text(
                'Needs Improvement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              for (final s in r.weaknesses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $s',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended Next Step',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Practice ${r.weaknesses.take(2).join(' and ')} questions.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => setState(() {
                  _stage = _Stage.setup;
                  _answers = [];
                  _result = null;
                }),
                child: const Text('Start Another Interview'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _count(String value, String label) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}
