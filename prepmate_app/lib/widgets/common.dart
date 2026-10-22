import 'package:flutter/material.dart';

import '../theme.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "2026-12-01" -> "1 Dec 2026". Falls back to the original text.
String formatDate(String yyyyMmDd) {
  final d = DateTime.tryParse('${yyyyMmDd}T00:00:00');
  if (d == null) return yyyyMmDd;
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

String monthShort(DateTime d) => _months[d.month - 1];

enum ToastKind { info, success, warning, error }

void showToast(
  BuildContext context,
  String message, [
  ToastKind kind = ToastKind.info,
]) {
  final color = switch (kind) {
    ToastKind.success => AppColors.green,
    ToastKind.warning => AppColors.orange,
    ToastKind.error => AppColors.red,
    ToastKind.info => AppColors.primary,
  };
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          Icon(
            kind == ToastKind.success
                ? Icons.check_circle
                : kind == ToastKind.info
                ? Icons.info
                : Icons.error,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.label,
    this.showValue = true,
  });

  final num value;
  final String? label;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final safe = value.isNaN ? 0.0 : value.clamp(0, 100).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showValue)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                if (showValue)
                  Text(
                    '${safe.round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: safe / 100,
            minHeight: 8,
            backgroundColor: AppColors.neutralSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.background = AppColors.neutralSoft,
    this.foreground = const Color(0xFF4B5563),
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

(Color, Color) statusColors(String status) {
  switch (status) {
    case 'Applied':
      return (AppColors.blueSoft, AppColors.blue);
    case 'Shortlisted':
      return (AppColors.orangeSoft, AppColors.orange);
    case 'Interview Scheduled':
      return (AppColors.primarySoft, AppColors.primary);
    case 'Selected':
      return (AppColors.greenSoft, AppColors.green);
    case 'Rejected':
      return (AppColors.redSoft, AppColors.red);
    default:
      return (AppColors.neutralSoft, const Color(0xFF4B5563));
  }
}

(Color, Color) priorityColors(String priority) {
  switch (priority.toUpperCase()) {
    case 'HIGH':
      return (AppColors.redSoft, AppColors.red);
    case 'MEDIUM':
      return (AppColors.orangeSoft, AppColors.orange);
    default:
      return (AppColors.blueSoft, AppColors.blue);
  }
}

(Color, Color) difficultyColors(String difficulty) {
  switch (difficulty) {
    case 'Easy':
      return (AppColors.greenSoft, AppColors.green);
    case 'Hard':
      return (AppColors.redSoft, AppColors.red);
    default:
      return (AppColors.orangeSoft, AppColors.orange);
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Labeled dropdown that works the same on every Flutter version.
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
    this.errorText,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T)? itemLabel;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, errorText: errorText),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel != null ? itemLabel!(item) : item.toString(),
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// Shows a banner-style inline message (info / warning / error).
class InlineAlert extends StatelessWidget {
  const InlineAlert(this.message, {super.key, this.kind = ToastKind.info});

  final String message;
  final ToastKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      ToastKind.error => (AppColors.redSoft, AppColors.red),
      ToastKind.warning => (AppColors.orangeSoft, AppColors.orange),
      ToastKind.success => (AppColors.greenSoft, AppColors.green),
      ToastKind.info => (AppColors.primarySoft, AppColors.primaryDark),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip(
    this.text, {
    super.key,
    this.background = AppColors.neutralSoft,
    this.foreground = const Color(0xFF374151),
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
