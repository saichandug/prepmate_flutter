import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/application.dart';
import '../providers/workspace_controller.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'application_form_screen.dart';
import 'dashboard_screen.dart' show CompanyAvatar;

const applicationStatuses = [
  'Applied',
  'Shortlisted',
  'Interview Scheduled',
  'Selected',
  'Rejected',
];

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key, required this.onNavigate});

  final void Function(String id) onNavigate;

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  String _query = '';
  String _status = 'All';
  String _sort = 'soonest';

  Future<void> _openForm({Application? editing}) async {
    final ws = context.read<WorkspaceController>();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApplicationFormScreen(
          editing: editing,
          onSave: (data) async {
            if (ws.isDuplicate(
              data.company,
              data.role,
              exceptId: editing?.id,
            )) {
              showToast(
                context,
                'An application for this company and role already exists.',
                ToastKind.warning,
              );
              return false;
            }
            final ApiException? error = await ws.saveApplication(
              data,
              editing: editing != null,
            );
            if (error != null) {
              if (mounted)
                showToast(
                  context,
                  error.message,
                  error.code == 'DUPLICATE'
                      ? ToastKind.warning
                      : ToastKind.error,
                );
              return false;
            }
            if (mounted)
              showToast(
                context,
                editing != null
                    ? 'Application updated.'
                    : 'Application saved successfully.',
                ToastKind.success,
              );
            return true;
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Application app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete application?'),
        content: const Text(
          'This will remove the application from your account. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await context.read<WorkspaceController>().deleteApplication(
      app.id,
    );
    if (!mounted) return;
    if (error != null) {
      showToast(context, error.message, ToastKind.error);
    } else {
      showToast(context, 'Application deleted.', ToastKind.success);
    }
  }

  void _view(Application app) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              '${app.company} · ${app.role}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _detail('Status', app.status),
            _detail('Interview', formatDate(app.interviewDate)),
            _detail('Preparation', '${app.preparationHours} hours'),
            _detail('Experience', app.experience),
            const SizedBox(height: 14),
            const Text(
              'Job Description',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            SelectableText(
              app.jd,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                context.read<WorkspaceController>().analyzeApplicationJd(
                  app.jd,
                );
                Navigator.pop(ctx);
                widget.onNavigate('preparation');
              },
              child: const Text('Analyze JD'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WorkspaceController>();
    final all = ws.applications;

    final filtered =
        all.where((a) {
          final q = _query.trim().toLowerCase();
          final matchesQuery =
              q.isEmpty || '${a.company} ${a.role}'.toLowerCase().contains(q);
          return matchesQuery && (_status == 'All' || a.status == _status);
        }).toList()..sort(
          (a, b) => _sort == 'soonest'
              ? a.interviewDate.compareTo(b.interviewDate)
              : b.interviewDate.compareTo(a.interviewDate),
        );

    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 600 ? 2 : 1);
        final cardWidth = (c.maxWidth - 32 - (columns - 1) * 14) / columns;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Track every opportunity.',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search company or role...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LabeledDropdown<String>(
                    label: 'Status',
                    value: _status,
                    items: const ['All', ...applicationStatuses],
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LabeledDropdown<String>(
                    label: 'Sort',
                    value: _sort,
                    items: const ['soonest', 'latest'],
                    itemLabel: (v) => v == 'soonest'
                        ? 'Soonest interview'
                        : 'Latest interview',
                    onChanged: (v) => setState(() => _sort = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.work_outline,
                  title: all.isNotEmpty
                      ? 'No matching applications found.'
                      : "You haven't added any applications yet.",
                  message: all.isNotEmpty
                      ? 'Change your search term or filters.'
                      : 'Add your first application to turn a job description into a preparation plan.',
                  actionLabel: all.isNotEmpty ? null : 'Add Application',
                  onAction: () => _openForm(),
                ),
              )
            else
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final app in filtered)
                    SizedBox(
                      width: cardWidth,
                      child: _ApplicationCard(
                        app: app,
                        progress: ws.getProgress(app.id),
                        onView: () => _view(app),
                        onEdit: () => _openForm(editing: app),
                        onDelete: () => _confirmDelete(app),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.app,
    required this.progress,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final Application app;
  final int progress;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = statusColors(app.status);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyAvatar(app.company),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      app.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Pill(app.status, background: bg, foreground: fg),
          const SizedBox(height: 10),
          Text(
            '${formatDate(app.interviewDate)}  ·  ${app.preparationHours}h prep',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ProgressBar(value: progress, label: 'Preparation'),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: onView, child: const Text('View')),
              TextButton(onPressed: onEdit, child: const Text('Edit')),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                onPressed: onDelete,
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
