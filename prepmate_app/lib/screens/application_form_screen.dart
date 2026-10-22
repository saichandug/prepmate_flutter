import 'package:flutter/material.dart';

import '../logic/validation.dart';
import '../models/application.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'applications_screen.dart' show applicationStatuses;

const experienceLevels = ['Fresher', '0–1 Years', '1–3 Years', '3+ Years'];

class ApplicationFormScreen extends StatefulWidget {
  const ApplicationFormScreen({super.key, this.editing, required this.onSave});

  final Application? editing;

  /// Returns true when saved. The form closes only on success.
  final Future<bool> Function(Application data) onSave;

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  late final TextEditingController _company;
  late final TextEditingController _role;
  late final TextEditingController _hours;
  late final TextEditingController _jd;
  late String _date;
  late String _experience;
  late String _status;
  Map<String, String> _errors = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _company = TextEditingController(text: e?.company ?? '');
    _role = TextEditingController(text: e?.role ?? '');
    _hours = TextEditingController(
      text: e == null ? '' : e.preparationHours.toString(),
    );
    _jd = TextEditingController(text: e?.jd ?? '');
    _date = e?.interviewDate ?? '';
    // Older records may hold a value that is not in the list; keep the dropdown valid.
    _experience = experienceLevels.contains(e?.experience)
        ? e!.experience
        : experienceLevels.first;
    _status = applicationStatuses.contains(e?.status)
        ? e!.status
        : applicationStatuses.first;
  }

  @override
  void dispose() {
    _company.dispose();
    _role.dispose();
    _hours.dispose();
    _jd.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse('${_date}T00:00:00') ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      final mm = picked.month.toString().padLeft(2, '0');
      final dd = picked.day.toString().padLeft(2, '0');
      setState(() {
        _date = '${picked.year}-$mm-$dd';
        _errors.remove('interviewDate');
      });
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    final form = <String, dynamic>{
      'company': _company.text.trim(),
      'role': _role.text.trim(),
      'interviewDate': _date,
      'preparationHours': _hours.text.trim(),
      'experience': _experience,
      'status': _status,
      'jd': _jd.text.trim(),
    };
    final errors = validateApplication(form);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _saving = true);
    final ok = await widget.onSave(
      Application(
        id: widget.editing?.id ?? '',
        company: form['company'] as String,
        role: form['role'] as String,
        interviewDate: _date,
        preparationHours: num.parse(form['preparationHours'] as String),
        experience: _experience,
        status: _status,
        jd: form['jd'] as String,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editing == null ? 'Add Application' : 'Edit Application',
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _company,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Company *',
                  hintText: 'e.g. Amazon',
                  errorText: _errors['company'],
                  counterText: '',
                ),
                onChanged: (_) => setState(() => _errors.remove('company')),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _role,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Job role *',
                  hintText: 'e.g. Software Engineer',
                  errorText: _errors['role'],
                  counterText: '',
                ),
                onChanged: (_) => setState(() => _errors.remove('role')),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Interview date *',
                    errorText: _errors['interviewDate'],
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    _date.isEmpty ? 'Select a date' : formatDate(_date),
                    style: TextStyle(
                      color: _date.isEmpty ? AppColors.muted : AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _hours,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Preparation time (hours/day) *',
                  hintText: 'e.g. 2',
                  errorText: _errors['preparationHours'],
                  helperText: 'Greater than 0 and at most 24',
                ),
                onChanged: (_) =>
                    setState(() => _errors.remove('preparationHours')),
              ),
              const SizedBox(height: 14),
              LabeledDropdown<String>(
                label: 'Experience level',
                value: _experience,
                items: experienceLevels,
                errorText: _errors['experience'],
                onChanged: (v) => setState(() => _experience = v),
              ),
              const SizedBox(height: 14),
              LabeledDropdown<String>(
                label: 'Status',
                value: _status,
                items: applicationStatuses,
                errorText: _errors['status'],
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _jd,
                maxLines: 8,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: 'Job description *',
                  hintText: 'Paste the job description...',
                  alignLabelWithHint: true,
                  errorText: _errors['jd'],
                ),
                onChanged: (_) => setState(() => _errors.remove('jd')),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.editing == null
                            ? 'Save Application'
                            : 'Update Application',
                      ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
