import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../logic/jd_analyzer.dart';
import '../logic/roadmap_generator.dart';
import '../logic/streak_manager.dart';
import '../models/application.dart';
import '../services/api_client.dart';

/// Holds everything the signed-in user sees: applications plus progress.
/// Applications are saved immediately through their own endpoints; progress
/// (streaks, roadmap, mock history...) is saved shortly after it changes.
class WorkspaceController extends ChangeNotifier {
  WorkspaceController(this._api);

  final ApiClient _api;

  bool loading = true;
  String? loadError;

  List<Application> applications = [];
  Map<String, bool> codingCompletion = {};
  Map<String, bool> roadmapCompletion = {};
  List<Map<String, dynamic>> mockHistory = [];
  Map<String, dynamic> streak = emptyStreak();
  Map<String, dynamic> analyzer = {'text': '', 'result': null};
  Map<String, dynamic>? roadmap;

  /// Set by the UI to show a message when saving progress fails.
  void Function(String message)? onSaveError;

  Timer? _saveTimer;
  String _lastSaved = '';
  bool _disposed = false;

  // ---------------------------------------------------------------- loading
  Future<void> load() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      final data = await _api.loadData();
      applications = ((data['applications'] as List?) ?? [])
          .map((a) => Application.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList();
      final p = Map<String, dynamic>.from((data['progress'] as Map?) ?? {});
      codingCompletion = _boolMap(p['codingCompletion']);
      roadmapCompletion = _boolMap(p['roadmapCompletion']);
      mockHistory = ((p['mockHistory'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final s = p['streak'];
      streak = {
        ...emptyStreak(),
        if (s is Map) ...Map<String, dynamic>.from(s),
      };
      final a = p['analyzer'];
      analyzer = a is Map
          ? {'text': '', 'result': null, ...Map<String, dynamic>.from(a)}
          : {'text': '', 'result': null};
      roadmap = p['roadmap'] is Map
          ? Map<String, dynamic>.from(p['roadmap'] as Map)
          : null;
      _lastSaved = _progressJson();
    } on ApiException catch (e) {
      if (e.status != 401) loadError = e.message;
    } catch (_) {
      loadError = 'Could not read your data from the server.';
    }
    loading = false;
    _notify();
  }

  Map<String, bool> _boolMap(Object? value) {
    if (value is! Map) return {};
    return value.map((k, v) => MapEntry(k.toString(), v == true));
  }

  // ----------------------------------------------------------- applications
  /// Returns null on success, or the error to show.
  Future<ApiException?> saveApplication(
    Application data, {
    required bool editing,
  }) async {
    try {
      final body = data.toJson();
      if (editing) {
        final res = await _api.updateApplication(data.id, body);
        final saved = Application.fromJson(
          Map<String, dynamic>.from(res['application'] as Map),
        );
        applications = applications
            .map((a) => a.id == saved.id ? saved : a)
            .toList();
      } else {
        final res = await _api.createApplication(body);
        final saved = Application.fromJson(
          Map<String, dynamic>.from(res['application'] as Map),
        );
        applications = [...applications, saved];
      }
      _notify();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  Future<ApiException?> deleteApplication(String id) async {
    try {
      await _api.deleteApplication(id);
      applications = applications.where((a) => a.id != id).toList();
      _notify();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  bool isDuplicate(String company, String role, {String? exceptId}) {
    final c = company.trim().toLowerCase();
    final r = role.trim().toLowerCase();
    return applications.any(
      (a) =>
          a.id != exceptId &&
          a.company.trim().toLowerCase() == c &&
          a.role.trim().toLowerCase() == r,
    );
  }

  /// 0-100 preparation progress shown on an application card.
  int getProgress(String appId) {
    final matches = applications.where((a) => a.id == appId);
    if (matches.isEmpty) return 0;
    final app = matches.first;
    final Map<String, dynamic>? result = app.id == analyzer['applicationId']
        ? _asMap(analyzer['result'])
        : (app.jd.isNotEmpty ? analyzeJD(app.jd) : null);
    final skillCount = ((result?['skills'] as List?) ?? []).length;
    final completed = roadmapCompletion.values.where((v) => v).length;
    if (skillCount == 0) return 0;
    final pct = ((completed / (skillCount < 1 ? 1 : skillCount)) * 100).round();
    return pct > 100 ? 100 : pct;
  }

  // --------------------------------------------------------------- analyzer
  void setAnalyzer(String text, Map<String, dynamic>? result) {
    analyzer = {...analyzer, 'text': text, 'result': result};
    _changed();
  }

  /// "Analyze JD" button on an application.
  void analyzeApplicationJd(String jd) => setAnalyzer(jd, analyzeJD(jd));

  void generateRoadmapForSkills(List<Map<String, dynamic>> skills) {
    final first = applications.isNotEmpty ? applications.first : null;
    final fallbackDate = DateTime.now()
        .add(const Duration(days: 21))
        .toIso8601String()
        .substring(0, 10);
    roadmap = generateRoadmap(
      company: first?.company ?? 'Your Target Company',
      role: first?.role ?? 'Software Engineer',
      experience: first?.experience ?? 'Fresher',
      interviewDate: first?.interviewDate ?? fallbackDate,
      preparationHours: first?.preparationHours ?? 2,
      skills: skills,
    );
    _changed();
  }

  // --------------------------------------------------------------- progress
  /// Returns true when the topic was just completed (not un-ticked).
  bool toggleRoadmap(String itemId) {
    final wasDone = roadmapCompletion[itemId] == true;
    roadmapCompletion = {...roadmapCompletion, itemId: !wasDone};
    if (!wasDone) streak = recordActivity(streak, 'roadmap');
    _changed();
    return !wasDone;
  }

  void completeCoding(String id) {
    codingCompletion = {...codingCompletion, id: true};
    streak = recordActivity(streak, 'coding');
    _changed();
  }

  void finishMock(Map<String, dynamic> record) {
    mockHistory = [record, ...mockHistory];
    streak = recordActivity(streak, 'mock');
    _changed();
  }

  // ----------------------------------------------------------------- saving
  Map<String, dynamic> _progressMap() => {
    'codingCompletion': codingCompletion,
    'roadmapCompletion': roadmapCompletion,
    'mockHistory': mockHistory,
    'streak': streak,
    'analyzer': analyzer,
    'roadmap': roadmap,
  };

  String _progressJson() => jsonEncode(_progressMap());

  void _changed() {
    _notify();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), flush);
  }

  /// Sends any unsaved progress now (also called when the app goes to the background).
  Future<void> flush() async {
    _saveTimer?.cancel();
    final json = _progressJson();
    if (json == _lastSaved) return;
    try {
      await _api.saveProgress(jsonDecode(json) as Map<String, dynamic>);
      _lastSaved = json;
    } on ApiException catch (e) {
      if (e.status != 401)
        onSaveError?.call('Could not save your progress: ${e.message}');
    }
  }

  Map<String, dynamic>? _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    super.dispose();
  }
}
