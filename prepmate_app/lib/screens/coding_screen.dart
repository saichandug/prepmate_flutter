import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/questions.dart';
import '../models/question.dart';
import '../providers/workspace_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CodingScreen extends StatefulWidget {
  const CodingScreen({super.key});

  @override
  State<CodingScreen> createState() => _CodingScreenState();
}

class _CodingScreenState extends State<CodingScreen> {
  String _company = 'All';
  String _topic = 'All';
  String _difficulty = 'All';
  String _state = 'All';
  String _query = '';
  String? _open;

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WorkspaceController>();
    final done = ws.codingCompletion;

    final topics = (questions.map((q) => q.topic).toSet().toList()..sort());
    final companies = (questions.map((q) => q.company).toSet().toList()
      ..sort());

    final filtered = questions.where((q) {
      final completed = done[q.id] == true;
      return (_company == 'All' || q.company == _company) &&
          (_topic == 'All' || q.topic == _topic) &&
          (_difficulty == 'All' || q.difficulty == _difficulty) &&
          (_state == 'All' ||
              (_state == 'Completed' ? completed : !completed)) &&
          '${q.question} ${q.topic} ${q.company}'.toLowerCase().contains(
            _query.toLowerCase(),
          );
    }).toList();

    final doneCount = questions.where((q) => done[q.id] == true).length;
    final pct = doneCount / (questions.isEmpty ? 1 : questions.length) * 100;

    return LayoutBuilder(
      builder: (context, c) {
        final half = c.maxWidth >= 640;
        final filterWidth = half ? (c.maxWidth - 32 - 10) / 2 : c.maxWidth - 32;

        Widget filter(Widget child) =>
            SizedBox(width: filterWidth, child: child);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Build interview muscle.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const Text(
              'Curated preparation material plus general interview questions.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$doneCount / ${questions.length}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Completed',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const Spacer(),
                      Text(
                        '${pct.round()}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ProgressBar(value: pct, showValue: false),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search questions...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                filter(
                  LabeledDropdown<String>(
                    label: 'Company',
                    value: _company,
                    items: ['All', ...companies],
                    onChanged: (v) => setState(() => _company = v),
                  ),
                ),
                filter(
                  LabeledDropdown<String>(
                    label: 'Topic',
                    value: _topic,
                    items: ['All', ...topics],
                    onChanged: (v) => setState(() => _topic = v),
                  ),
                ),
                filter(
                  LabeledDropdown<String>(
                    label: 'Difficulty',
                    value: _difficulty,
                    items: const ['All', 'Easy', 'Medium', 'Hard'],
                    onChanged: (v) => setState(() => _difficulty = v),
                  ),
                ),
                filter(
                  LabeledDropdown<String>(
                    label: 'Status',
                    value: _state,
                    items: const ['All', 'Completed', 'Not Completed'],
                    onChanged: (v) => setState(() => _state = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              const AppCard(
                child: EmptyState(
                  icon: Icons.search,
                  title: 'No questions found.',
                  message: 'Change your search term or filters.',
                ),
              )
            else
              for (var i = 0; i < filtered.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuestionCard(
                    index: i + 1,
                    question: filtered[i],
                    completed: done[filtered[i].id] == true,
                    open: _open == filtered[i].id,
                    onToggleOpen: () => setState(
                      () => _open = _open == filtered[i].id
                          ? null
                          : filtered[i].id,
                    ),
                    onComplete: () {
                      context.read<WorkspaceController>().completeCoding(
                        filtered[i].id,
                      );
                      showToast(
                        context,
                        'Question marked complete.',
                        ToastKind.success,
                      );
                    },
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.completed,
    required this.open,
    required this.onToggleOpen,
    required this.onComplete,
  });

  final int index;
  final Question question;
  final bool completed;
  final bool open;
  final VoidCallback onToggleOpen;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final (bg, fg) = difficultyColors(q.difficulty);
    return AppCard(
      color: completed ? AppColors.greenSoft : AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                index.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TagChip(q.company),
              Pill(q.difficulty, background: bg, foreground: fg),
              Text(
                q.topic,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          if (open) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Answer / Explanation',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    q.answer,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Important concepts',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final c in q.concepts) TagChip(c)],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: onToggleOpen,
                child: Text(open ? 'Hide Answer' : 'View Answer'),
              ),
              const Spacer(),
              completed
                  ? const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.green,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                      ),
                      onPressed: onComplete,
                      child: const Text('Mark Completed'),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
