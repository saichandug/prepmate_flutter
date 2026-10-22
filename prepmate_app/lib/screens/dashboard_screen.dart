import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workspace_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  final void Function(String id) onNavigate;

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WorkspaceController>();
    final apps = ws.applications;

    final interviews = apps
        .where(
          (a) => a.status == 'Interview Scheduled' || a.status == 'Shortlisted',
        )
        .length;
    final now = DateTime.now();
    final upcomingList = apps.where((a) {
      final d = DateTime.tryParse('${a.interviewDate}T23:59:59');
      return d != null && !d.isBefore(now);
    }).toList()..sort((a, b) => a.interviewDate.compareTo(b.interviewDate));
    final upcoming = upcomingList.isEmpty ? null : upcomingList.first;

    final weeks = (ws.roadmap?['weeks'] as List?) ?? [];
    final items = [
      for (final w in weeks)
        ...((w as Map)['items'] as List).map(
          (i) => Map<String, dynamic>.from(i as Map),
        ),
    ];
    final completed = items
        .where((i) => ws.roadmapCompletion[i['id']] == true)
        .length;
    final progress = items.isEmpty
        ? 0
        : (completed / items.length * 100).round();
    final nextItems = items
        .where((i) => ws.roadmapCompletion[i['id']] != true)
        .toList();
    final next = nextItems.isEmpty ? null : nextItems.first;

    final streakNow = ((ws.streak['current'] as num?) ?? 0).toInt();

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 720;
        final tileWidth = wide
            ? (c.maxWidth - 32 - 36) / 4
            : (c.maxWidth - 32 - 12) / 2;

        Widget upcomingCard = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                eyebrow: 'Upcoming interview',
                title: 'Next on your calendar',
                trailing: TextButton(
                  onPressed: () => onNavigate('applications'),
                  child: const Text('View all'),
                ),
              ),
              const SizedBox(height: 12),
              if (upcoming == null)
                EmptyState(
                  icon: Icons.event_outlined,
                  title: 'No upcoming interviews',
                  message: 'Add an application with an interview date to see it here.',
                  actionLabel: 'Add Application',
                  onAction: () => onNavigate('applications'),
                )
              else
                Row(
                  children: [
                    Container(
                      width: 62,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${DateTime.parse('${upcoming.interviewDate}T00:00:00').day}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            monthShort(
                              DateTime.parse(
                                '${upcoming.interviewDate}T00:00:00',
                              ),
                            ),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            upcoming.company,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            upcoming.role,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 6),
                          Pill(upcoming.status),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );

        Widget studyCard = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                eyebrow: 'Study next',
                title: 'Keep momentum',
              ),
              const SizedBox(height: 12),
              if (next == null)
                const EmptyState(
                  icon: Icons.check,
                  title: "You're all caught up!",
                  message:
                      'Analyze a job description to create your next roadmap.',
                )
              else ...[
                Builder(
                  builder: (_) {
                    final (bg, fg) = priorityColors(
                      (next['priority'] ?? 'LOW').toString(),
                    );
                    return Pill(
                      (next['priority'] ?? 'LOW').toString(),
                      background: bg,
                      foreground: fg,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  (next['topic'] ?? '').toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${next['minutes']} minutes estimated',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => onNavigate('preparation'),
                    child: const Text('Start Learning'),
                  ),
                ),
              ],
            ],
          ),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF171125), Color(0xFF36216B)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your preparation command center',
                    style: TextStyle(
                      color: Color(0xFFA78BFA),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Turn your job application into a preparation plan.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Track opportunities, extract skills, practice the right questions and walk into interviews prepared.',
                    style: TextStyle(color: Color(0xFFC9C1DC), height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => onNavigate('applications'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Application'),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF6D5BA8)),
                        ),
                        onPressed: () => onNavigate('preparation'),
                        child: const Text('Analyze JD'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: wide ? 12 : 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: StatTile(
                    icon: Icons.work_outline,
                    label: 'Total Applications',
                    value: '${apps.length}',
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: StatTile(
                    icon: Icons.event_available_outlined,
                    label: 'Interviews',
                    value: '$interviews',
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: StatTile(
                    icon: Icons.track_changes,
                    label: 'Preparation Progress',
                    value: '$progress%',
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: StatTile(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Current Streak',
                    value: '${streakNow}d',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: upcomingCard),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: studyCard),
                ],
              )
            else ...[
              upcomingCard,
              const SizedBox(height: 16),
              studyCard,
            ],
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    eyebrow: 'Recent applications',
                    title: 'Latest opportunities',
                    trailing: TextButton(
                      onPressed: () => onNavigate('applications'),
                      child: const Text('Manage'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (apps.isEmpty)
                    EmptyState(
                      icon: Icons.work_outline,
                      title: "You haven't added any applications yet.",
                      message:
                          "Start with a role you're currently applying for.",
                      actionLabel: 'Add Application',
                      onAction: () => onNavigate('applications'),
                    )
                  else
                    for (final app in apps.reversed.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CompanyAvatar(app.company),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app.company,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    app.role,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Pill(app.status),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 70,
                              child: ProgressBar(
                                value: ws.getProgress(app.id),
                                showValue: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class CompanyAvatar extends StatelessWidget {
  const CompanyAvatar(this.company, {super.key});
  final String company;

  @override
  Widget build(BuildContext context) {
    final text = company.length >= 2 ? company.substring(0, 2) : company;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
