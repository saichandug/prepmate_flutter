import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'providers/auth_controller.dart';
import 'providers/workspace_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'services/api_client.dart';
import 'services/token_store.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PrepMateApp());
}

class PrepMateApp extends StatefulWidget {
  const PrepMateApp({super.key});

  @override
  State<PrepMateApp> createState() => _PrepMateAppState();
}

class _PrepMateAppState extends State<PrepMateApp> {
  late final ApiClient _api;
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(apiBaseUrl);
    _auth = AuthController(_api, TokenStore())..init();
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _api),
        ChangeNotifierProvider<AuthController>.value(value: _auth),
      ],
      child: MaterialApp(
        title: 'PrepMate',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    switch (auth.status) {
      case AuthStatus.checking:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading PrepMate...',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        );
      case AuthStatus.signedOut:
        return const AuthScreen();
      case AuthStatus.signedIn:
        // Keyed by user id so a different account never sees the previous one's data.
        return ChangeNotifierProvider<WorkspaceController>(
          key: ValueKey(auth.user!.id),
          create: (ctx) => WorkspaceController(ctx.read<ApiClient>())..load(),
          child: const HomeShell(),
        );
    }
  }
}
