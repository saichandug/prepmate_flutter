import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/streak_manager.dart';
import '../providers/workspace_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key, required this.onNavigate});

  final void Function(String id) onNavigate;

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WorkspaceController>();
    final activities = getTodayActivities(ws.streak);
    final current = ((ws.streak['current'] as num?) ?? 0).toInt();
    final best = ((ws.streak['best'] as num?) ?? 0).toInt();
    const types = [
      ('roadmap', 'Roadmap topic', 'preparation'),
      ('coding', 'Coding question', 'coding'),
      ('mock', 'Mock interview', 'mock'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFFB45309)],
            ),
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 44)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily preparation',
                      style: TextStyle(
                        color: Color(0xFFFFEDD5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$current Day Streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Meaningful preparation beats simply opening the app.',
                      style: TextStyle(color: Color(0xFFFFEDD5), height: 1.35),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Text(
                    'Best streak',
                    style: TextStyle(color: Color(0xFFFFEDD5), fontSize: 11),
                  ),
                  Text(
                    '$best days',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                eyebrow: "Today's progress",
                title:
                    '${activities.length > 3 ? 3 : activities.length} / 3 activities',
              ),
              const SizedBox(height: 14),
              for (final (id, label, destination) in types)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: activities.contains(id)
                        ? AppColors.greenSoft
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onNavigate(destination),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              activities.contains(id)
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: activities.contains(id)
                                  ? AppColors.green
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    activities.contains(id)
                                        ? 'Completed today · Open'
                                        : 'Start now →',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (activities.length < 3)
                const InlineAlert(
                  'Complete one more meaningful activity to maintain your streak.',
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How streaks work',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'Only completing a roadmap topic, coding question, or mock interview counts. Opening PrepMate does not increase the streak.',
                style: TextStyle(color: AppColors.muted, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
