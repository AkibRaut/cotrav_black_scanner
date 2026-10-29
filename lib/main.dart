import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/navigation/fade_route.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/login/view/login_page.dart';
import 'features/scanner/view/scanner_page.dart';
import 'features/splash/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF070707),
    ),
  );
  runApp(CotravBlackScannerApp(authRepository: AuthRepository()));
}

class CotravBlackScannerApp extends StatefulWidget {
  const CotravBlackScannerApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<CotravBlackScannerApp> createState() => _CotravBlackScannerAppState();
}

class _CotravBlackScannerAppState extends State<CotravBlackScannerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    widget.authRepository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: widget.authRepository,
      child: BlocProvider(
        create: (_) => AuthBloc(repository: widget.authRepository)..add(const AuthStarted()),
        child: MaterialApp(
          title: 'Cotrav Black Pass',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          navigatorKey: _navigatorKey,
          home: const SplashPage(),
          builder: (context, child) => BlocListener<AuthBloc, AuthState>(
            // The splash screen handles the first decision; after that, every
            // login or logout swaps the whole stack.
            listenWhen: (previous, current) =>
                previous.status != AuthStatus.unknown && previous.status != current.status,
            listener: (context, state) {
              final page = state.status == AuthStatus.authenticated ? const ScannerPage() : const LoginPage();
              _navigatorKey.currentState?.pushAndRemoveUntil(fadeRoute<void>(page), (_) => false);
            },
            child: child!,
          ),
        ),
      ),
    );
  }
}
