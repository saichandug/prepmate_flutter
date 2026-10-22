import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/jd_analyzer.dart';
import '../logic/validation.dart';
import '../providers/workspace_controller.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// JD analyzer, followed by the generated roadmap once one exists.
class PreparationScreen extends StatelessWidget {
  const PreparationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WorkspaceController>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _JdAnalyzer(),
        if (ws.roadmap != null) ...[
          const SizedBox(height: 20),
          _RoadmapView(roadmap: ws.roadmap!),
        ],
      ],
    );
  }
}

class _JdAnalyzer extends StatefulWidget {
  const _JdAnalyzer();

  @override
  State<_JdAnalyzer> createState() => _JdAnalyzerState();
}

class _JdAnalyzerState extends State<_JdAnalyzer> {
  late final TextEditingController _text;
  String _syncedText = '';
  String _error = '';
  String _aiError = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final saved = (context.read<WorkspaceController>().analyzer['text'] ?? '')
        .toString();
    _text = TextEditingController(text: saved);
    _syncedText = saved;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_busy) return;
    final ws = context.read<WorkspaceController>();
    final text = _text.text;
    final validation = validateJD(text);
    if (validation.isNotEmpty) {
      setState(() => _error = validation);
      ws.setAnalyzer(text, null);
      _syncedText = text;
      return;
    }

    setState(() {
      _busy = true;
      _error = '';
      _aiError = '';
    });
    final local = analyzeJD(text);
    _syncedText = text;
    ws.setAnalyzer(text, local);

    try {
      final ai = await context.read<ApiClient>().gemini('jd', {'text': text});
      final aiSkills = ((ai['skills'] as List?) ?? [])
          .whereType<Map>()
          .where((s) => (s['name'] ?? '').toString().isNotEmpty)
          .take(12)
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
      final aiCategories = (ai['categories'] as List?) ?? [];
      final merged = <String, dynamic>{
        ...local,
        'status': aiSkills.isNotEmpty ? local['status'] : 'unrelated',
        'skills': aiSkills.isNotEmpty ? aiSkills : local['skills'],
        'categories': aiCategories.isNotEmpty
            ? aiCategories
            : local['categories'],
        'keywords': ai['keywords'] is List ? ai['keywords'] : local['keywords'],
        'ai': ai,
      };
      ws.setAnalyzer(text, merged);
      if (mounted)
        showToast(
          context,
          'Job description analyzed with Gemini AI.',
          ToastKind.success,
        );
    } catch (_) {
      if (mounted) {
        setState(
          () => _aiError = "Gemini is unavailable right now. Showing PrepMate's built-in analysis instead.",
        );
        showToast(
          context,
          'AI analysis unavailable; built-in analysis is still available.',
          ToastKind.warning,
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WorkspaceController>();

    // Another screen (the "Analyze JD" button on an application) replaced the text.
    final externalText = (ws.analyzer['text'] ?? '').toString();
    if (externalText != _syncedText) {
      _syncedText = externalText;
      _error = '';
      // Updating a controller while building can throw, so do it right after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _text.text != externalText) _text.text = externalText;
      });
    }
    final result = ws.analyzer['result'] is Map
        ? Map<String, dynamic>.from(ws.analyzer['result'] as Map)
        : null;

    final input = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            eyebrow: 'AI + rule-based analysis',
            title: 'What should you prepare?',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            minLines: 8,
            maxLines: 14,
            maxLength: 4000,
            decoration: const InputDecoration(
              labelText: 'Job Description',
              hintText: 'Paste a software job description...',
              alignLabelWithHint: true,
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            InlineAlert(_error, kind: ToastKind.error),
          ],
          if (_aiError.isNotEmpty) ...[
            const SizedBox(height: 8),
            InlineAlert(_aiError, kind: ToastKind.warning),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _run,
              child: Text(
                _busy ? 'Analyzing with Gemini...' : 'Analyze Job Description',
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        input,
        const SizedBox(height: 16),
        AppCard(
          child: _ResultView(
            result: result,
            onTryAgain: () {
              _text.clear();
              _syncedText = '';
              ws.setAnalyzer('', null);
            },
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onTryAgain});

  final Map<String, dynamic>? result;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    final r = result;
    if (r == null) {
      return const EmptyState(
        icon: Icons.auto_awesome,
        title: 'Your analysis will appear here.',
        message: 'Paste a valid job description and Gemini will identify the skills, requirements and preparation focus.',
      );
    }
    final status = (r['status'] ?? '').toString();
    final ai = r['ai'] is Map
        ? Map<String, dynamic>.from(r['ai'] as Map)
        : null;

    if (status == 'unrelated') {
      return EmptyState(
        icon: Icons.warning_amber_rounded,
        title: 'No Relevant Job Skills Found',
        message:
            (r['message'] ??
                    ai?['summary'] ??
                    'Please enter a genuine job description containing relevant requirements or skills.')
                .toString(),
        actionLabel: 'Try Again',
        onAction: onTryAgain,
      );
    }
    if (status == 'short' || status == 'empty') {
      return EmptyState(
        icon: Icons.priority_high,
        title: (r['message'] ?? '').toString(),
        message:
            'Add more relevant job requirements before generating a roadmap.',
      );
    }

    final skills = ((r['skills'] as List?) ?? [])
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();
    final categories = ((r['categories'] as List?) ?? [])
        .map((c) => c.toString())
        .toList();
    final responsibilities = ((ai?['responsibilities'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    final missing = ((ai?['missingSkillSuggestions'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          eyebrow: 'Detected skills',
          title: '${skills.length} skills found',
          trailing: Pill(ai != null ? 'Gemini enhanced' : 'Built-in'),
        ),
        if (ai?['summary'] != null && ai!['summary'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          InlineAlert(ai['summary'].toString()),
        ],
        if (status == 'limited') ...[
          const SizedBox(height: 12),
          const InlineAlert(
            'Recommendations are based only on the detected information.',
            kind: ToastKind.warning,
          ),
        ],
        const SizedBox(height: 14),
        for (final priority in const ['HIGH', 'MEDIUM', 'LOW'])
          Builder(
            builder: (_) {
              final items = skills
                  .where((s) => s['priority'] == priority)
                  .toList();
              final (bg, fg) = priorityColors(priority);
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pill(
                          '$priority PRIORITY',
                          background: bg,
                          foreground: fg,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${items.length}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        items.isEmpty
                            ? 'None detected'
                            : items.map((i) => i['name']).join(' · '),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        heading('Detected Skills'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in skills)
              Builder(
                builder: (_) {
                  final (bg, fg) = priorityColors(
                    (s['priority'] ?? 'LOW').toString(),
                  );
                  return TagChip(
                    (s['name'] ?? '').toString(),
                    background: bg,
                    foreground: fg,
                  );
                },
              ),
          ],
        ),
        if (ai?['education'] != null &&
            ai!['education'].toString().isNotEmpty) ...[
          heading('Education'),
          Text(
            ai['education'].toString(),
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
        ],
        if (ai?['experience'] != null &&
            ai!['experience'].toString().isNotEmpty) ...[
          heading('Experience'),
          Text(
            ai['experience'].toString(),
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
        ],
        if (responsibilities.isNotEmpty) ...[
          heading('Key Responsibilities'),
          for (final item in responsibilities)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
        ],
        if (missing.isNotEmpty) ...[
          heading('Suggested Skills to Prepare'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final m in missing) TagChip(m)],
          ),
        ],
        if (categories.isNotEmpty) ...[
          heading('Skill Categories'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in categories) TagChip(c)],
          ),
        ],
        heading('Suggested Preparation Topics'),
        ProgressBar(
          value: skills.length * 10 > 100 ? 100 : skills.length * 10,
          label: 'Coverage snapshot',
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              context.read<WorkspaceController>().generateRoadmapForSkills(
                skills,
              );
              showToast(
                context,
                'Preparation roadmap generated.',
                ToastKind.success,
              );
            },
            child: const Text('Generate Preparation Roadmap'),
          ),
        ),
      ],
    );
  }
}

class _RoadmapView extends StatelessWidget {
  const _RoadmapView({required this.roadmap});

  final Map<String, dynamic> roadmap;

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WorkspaceController>();
    final meta = Map<String, dynamic>.from((roadmap['meta'] as Map?) ?? {});
    final weeks = ((roadmap['weeks'] as List?) ?? [])
        .map((w) => Map<String, dynamic>.from(w as Map))
        .toList();
    final items = [
      for (final w in weeks)
        ...((w['items'] as List?) ?? []).map(
          (i) => Map<String, dynamic>.from(i as Map),
        ),
    ];
    final completion = ws.roadmapCompletion;
    final completed = items.where((i) => completion[i['id']] == true).length;
    final percent = items.isEmpty
        ? 0
        : (completed / items.length * 100).round();
    final nextList = items.where((i) => completion[i['id']] != true).toList();
    final next = nextList.isEmpty ? null : nextList.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF171125), Color(0xFF36216B)],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${meta['company']} · ${meta['role']}',
                      style: const TextStyle(
                        color: Color(0xFFA78BFA),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Preparation Roadmap',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meta['preparationHours']} hours/day · Interview ${formatDate((meta['interviewDate'] ?? '').toString())}',
                      style: const TextStyle(
                        color: Color(0xFFC9C1DC),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'complete',
                    style: TextStyle(color: Color(0xFFC9C1DC), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (next != null)
          AppCard(
            color: AppColors.primarySoft,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Study next',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        (next['topic'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${next['priority']} · ${next['minutes']} minutes',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () => showToast(
                    context,
                    'Start with the highest-priority topic below, then tick it off.',
                    ToastKind.info,
                  ),
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        ProgressBar(
          value: percent,
          label: '$completed / ${items.length} topics completed',
        ),
        const SizedBox(height: 14),
        for (final week in weeks)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WEEK ${week['week']}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              (week['title'] ?? '').toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Pill(
                        '${((week['items'] as List)).where((i) => completion[(i as Map)['id']] == true).length}/${(week['items'] as List).length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final item in ((week['items'] as List).map(
                    (i) => Map<String, dynamic>.from(i as Map),
                  )))
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      value: completion[item['id']] == true,
                      title: Text(
                        (item['topic'] ?? '').toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: completion[item['id']] == true
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        '${item['minutes']} min · ${item['priority']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onChanged: (_) {
                        final nowDone = ws.toggleRoadmap(item['id'].toString());
                        if (nowDone)
                          showToast(
                            context,
                            'Great work! Topic marked complete.',
                            ToastKind.success,
                          );
                      },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
