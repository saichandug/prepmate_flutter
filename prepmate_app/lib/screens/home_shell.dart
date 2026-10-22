import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../providers/workspace_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'applications_screen.dart';
import 'coding_screen.dart';
import 'dashboard_screen.dart';
import 'mock_interview_screen.dart';
import 'preparation_screen.dart';
import 'streak_screen.dart';

class _Section {
  final String id;
  final String label;
  final IconData icon;
  final String title;
  final String subtitle;
  const _Section(this.id, this.label, this.icon, this.title, this.subtitle);
}

const _sections = [
  _Section(
    'dashboard',
    'Dashboard',
    Icons.dashboard_outlined,
    'Dashboard',
    'Your preparation at a glance',
  ),
  _Section(
    'applications',
    'Applications',
    Icons.work_outline,
    'Applications',
    'Track every opportunity',
  ),
  _Section(
    'preparation',
    'Preparation',
    Icons.map_outlined,
    'Preparation',
    'Analyze a JD and follow your roadmap',
  ),
  _Section(
    'coding',
    'Coding Practice',
    Icons.code,
    'Coding Practice',
    'Build interview muscle',
  ),
  _Section(
    'mock',
    'Mock Interview',
    Icons.mic_none,
    'Mock Interview',
    'Practice under real pressure',
  ),
  _Section(
    'streak',
    'Daily Streak',
    Icons.local_fire_department_outlined,
    'Daily Streak',
    'Keep your momentum going',
  ),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  String _active = 'dashboard';
  late final WorkspaceController _ws;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ws = context.read<WorkspaceController>();
    _ws.onSaveError = (message) {
      if (mounted) showToast(context, message, ToastKind.error);
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Send unsaved progress when the app goes to the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _ws.flush();
  }

  void _go(String id) => setState(() => _active = id);

  Future<void> _signOut() async {
    await _ws.flush();
    if (!mounted) return;
    await context.read<AuthController>().logout();
  }

  Widget _content(WorkspaceController ws) {
    switch (_active) {
      case 'applications':
        return ApplicationsScreen(onNavigate: _go);
      case 'preparation':
        return const PreparationScreen();
      case 'coding':
        return const CodingScreen();
      case 'mock':
        return const MockInterviewScreen();
      case 'streak':
        return StreakScreen(onNavigate: _go);
      default:
        return DashboardScreen(onNavigate: _go);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WorkspaceController>();
    final user = context.watch<AuthController>().user;
    final wide = MediaQuery.of(context).size.width >= 900;
    final section = _sections.firstWhere((s) => s.id == _active);

    if (ws.loading || ws.loadError != null) {
      return Scaffold(
        body: Center(
          child: ws.loadError == null
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading your workspace...',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AppCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Could not load your workspace',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ws.loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton(
                                onPressed: ws.load,
                                child: const Text('Try again'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: _signOut,
                                child: const Text('Sign out'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      );
    }

    final sidebar = _Sidebar(
      active: _active,
      onSelect: (id) {
        _go(id);
        if (!wide) Navigator.of(context).maybePop(); // close the drawer
      },
    );

    return Scaffold(
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: AppColors.sidebar,
              child: SafeArea(child: sidebar),
            ),
      appBar: AppBar(
        titleSpacing: wide ? 24 : 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            Text(
              section.subtitle,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            PopupMenuButton<String>(
              tooltip: user.email,
              offset: const Offset(0, 46),
              onSelected: (v) {
                if (v == 'logout') _signOut();
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 10),
                      Text('Sign out'),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    user.name.trim().isEmpty
                        ? '?'
                        : user.name.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                SizedBox(
                  width: 250,
                  child: Material(
                    color: AppColors.sidebar,
                    child: SafeArea(child: sidebar),
                  ),
                ),
                Expanded(child: _page(ws)),
              ],
            )
          : _page(ws),
    );
  }

  Widget _page(WorkspaceController ws) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: _content(ws),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.active, required this.onSelect});

  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  'P',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PrepMate',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Job ready, faster.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (final s in _sections)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Material(
              color: s.id == active
                  ? AppColors.sidebarActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => onSelect(s.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        s.icon,
                        size: 20,
                        color: s.id == active
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        s.label,
                        style: TextStyle(
                          color: s.id == active
                              ? Colors.white
                              : const Color(0xFFD1D5DB),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
