import 'dart:convert';

import 'package:cotrav_black_scanner/core/config/api_config.dart';
import 'package:cotrav_black_scanner/features/auth/bloc/auth_bloc.dart';
import 'package:cotrav_black_scanner/features/auth/data/auth_repository.dart';
import 'package:cotrav_black_scanner/features/auth/data/auth_validators.dart';
import 'package:cotrav_black_scanner/features/auth/data/session_store.dart';
import 'package:cotrav_black_scanner/features/auth/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:cotrav_black_scanner/features/auth/login/bloc/login_bloc.dart';
import 'package:cotrav_black_scanner/features/auth/login/view/login_page.dart';
import 'package:cotrav_black_scanner/features/auth/models/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Fake API: records each request and answers from [responses] by URL.
class FakeApi {
  FakeApi(this.responses);

  final Map<String, Object> responses;
  final requests = <http.Request>[];

  late final client = MockClient((request) async {
    requests.add(request);
    final body = responses[request.url.toString()];
    if (body == null) return http.Response('not found', 404);
    return http.Response(body is String ? body : jsonEncode(body), 200, headers: {'content-type': 'application/json'});
  });
}

/// The auth background glow loops forever, so pumpAndSettle never returns.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _ok = {'success': '1', 'message': 'OTP sent successfully'};
const _loginOk = {
  'success': '1',
  'data': {'name': 'Akib Raut', 'access_token': 'tok-123'},
};

void main() {
  group('AuthRepository', () {
    test('password login posts a form body and stores the session', () async {
      final api = FakeApi({ApiConfig.passwordLogin: _loginOk});
      final store = MemorySessionStore();
      final repo = AuthRepository(client: api.client, store: store);
      final emitted = expectLater(repo.sessionChanges, emits(isA<AuthSession>()));

      final session = await repo.loginWithPassword(loginId: '  Akib@Cotrav.co ', password: 'Secret1');

      final request = api.requests.single;
      expect(request.method, 'POST');
      expect(request.headers['content-type'], contains('application/x-www-form-urlencoded'));
      expect(request.bodyFields, {'login_id': 'akib@cotrav.co', 'password': 'Secret1'});
      expect(session.token, 'tok-123');
      expect(session.displayName, 'Akib Raut');
      expect(await store.read(), session);
      await emitted;
    });

    test('a success "0" response surfaces the server error', () async {
      final api = FakeApi({
        ApiConfig.passwordLogin: {'success': '0', 'error': 'Incorrect Email ID/Contact No or Password!!!'},
      });
      final repo = AuthRepository(client: api.client, store: MemorySessionStore());

      expect(
        () => repo.loginWithPassword(loginId: 'a@b.co', password: 'x'),
        throwsA(
          isA<AuthException>().having((e) => e.message, 'message', 'Incorrect Email ID/Contact No or Password!!!'),
        ),
      );
    });

    test('non-JSON responses become a readable error', () async {
      final api = FakeApi({ApiConfig.sendOtp: '<html>oops</html>'});
      final repo = AuthRepository(client: api.client, store: MemorySessionStore());

      expect(() => repo.sendLoginOtp('a@b.co'), throwsA(isA<AuthException>()));
    });

    test('OTP, forgot and reset send the documented fields', () async {
      final api = FakeApi({
        ApiConfig.sendOtp: _ok,
        ApiConfig.verifyOtp: _loginOk,
        ApiConfig.forgotPassword: _ok,
        ApiConfig.resetPassword: _ok,
      });
      final repo = AuthRepository(client: api.client, store: MemorySessionStore());

      await repo.sendLoginOtp('9876543210');
      await repo.verifyLoginOtp(loginId: '9876543210', otp: ' 1234 ');
      await repo.forgotPassword('A@B.co');
      await repo.resetPassword(loginId: 'A@B.co', otp: '5678', newPassword: 'NewPass1');

      expect(api.requests.map((r) => r.bodyFields), [
        {'login_id': '9876543210'},
        {'login_id': '9876543210', 'otp': '1234'},
        {'login_id': 'a@b.co'},
        {'login_id': 'a@b.co', 'otp': '5678', 'new_password': 'NewPass1'},
      ]);
    });

    test('logout clears the store and emits null', () async {
      final store = MemorySessionStore(const AuthSession(loginId: 'a@b.co'));
      final repo = AuthRepository(client: FakeApi({}).client, store: store);
      final emitted = expectLater(repo.sessionChanges, emits(isNull));

      await repo.logout();

      expect(await store.read(), isNull);
      await emitted;
    });
  });

  group('AuthValidators', () {
    test('accept emails and phone numbers', () {
      expect(AuthValidators.loginId('a@b.co'), isNull);
      expect(AuthValidators.loginId('98765 43210'), isNull);
      expect(AuthValidators.loginId('+919876543210'), isNull);
      expect(AuthValidators.loginId(''), isNotNull);
      expect(AuthValidators.loginId('hello'), isNotNull);
      expect(AuthValidators.otp('12a4'), isNotNull);
      expect(AuthValidators.otp('123456'), isNull);
    });
  });

  group('AuthBloc', () {
    test('restores the saved session, then follows logout', () async {
      final repo = AuthRepository(
        client: FakeApi({}).client,
        store: MemorySessionStore(const AuthSession(loginId: 'a@b.co')),
      );
      final bloc = AuthBloc(repository: repo)..add(const AuthStarted());

      await expectLater(
        bloc.stream,
        emits(isA<AuthState>().having((s) => s.status, 'status', AuthStatus.authenticated)),
      );
      bloc.add(const AuthLogoutRequested());
      await expectLater(
        bloc.stream,
        emits(isA<AuthState>().having((s) => s.status, 'status', AuthStatus.unauthenticated)),
      );
      await bloc.close();
    });
  });

  group('LoginBloc', () {
    test('OTP flow: send, wrong OTP, then verify', () async {
      final api = FakeApi({
        ApiConfig.sendOtp: _ok,
        ApiConfig.verifyOtp: {'success': '0', 'error': 'Invalid OTP'},
      });
      final bloc = LoginBloc(
        repository: AuthRepository(client: api.client, store: MemorySessionStore()),
      );

      bloc.add(const LoginModeChanged(LoginMode.otp));
      bloc.add(const LoginOtpRequested('A@B.co'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<LoginState>()
              .having((s) => s.status, 'status', LoginStatus.otpSent)
              .having((s) => s.otpLoginId, 'otpLoginId', 'a@b.co')
              .having((s) => s.message, 'message', 'OTP sent successfully'),
        ),
      );

      bloc.add(const LoginOtpSubmitted('0000'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<LoginState>()
              .having((s) => s.status, 'status', LoginStatus.failure)
              .having((s) => s.error, 'error', 'Invalid OTP')
              .having((s) => s.otpSent, 'otpSent', true),
        ),
      );

      api.responses[ApiConfig.verifyOtp] = _loginOk;
      bloc.add(const LoginOtpSubmitted('1234'));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<LoginState>().having((s) => s.status, 'status', LoginStatus.success)),
      );
      await bloc.close();
    });
  });

  group('ForgotPasswordBloc', () {
    test('request OTP then reset', () async {
      final api = FakeApi({ApiConfig.forgotPassword: _ok, ApiConfig.resetPassword: _ok});
      final bloc = ForgotPasswordBloc(
        repository: AuthRepository(client: api.client, store: MemorySessionStore()),
      );

      bloc.add(const ForgotPasswordOtpRequested('a@b.co'));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<ForgotPasswordState>().having((s) => s.status, 'status', ForgotPasswordStatus.otpSent)),
      );
      bloc.add(const ForgotPasswordResetSubmitted(otp: '1234', newPassword: 'NewPass1'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<ForgotPasswordState>()
              .having((s) => s.status, 'status', ForgotPasswordStatus.success)
              .having((s) => s.loginId, 'loginId', 'a@b.co'),
        ),
      );
      await bloc.close();
    });
  });

  group('LoginPage', () {
    setUp(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1170, 2532);
      view.devicePixelRatio = 3;
      addTearDown(view.reset);
    });

    Widget app(AuthRepository repo) => RepositoryProvider.value(
      value: repo,
      child: const MaterialApp(home: LoginPage()),
    );

    testWidgets('validates, switches to OTP and logs in with a password', (tester) async {
      final api = FakeApi({ApiConfig.passwordLogin: _loginOk});
      final store = MemorySessionStore();
      final repo = AuthRepository(client: api.client, store: store);
      await tester.pumpWidget(app(repo));
      await settle(tester);

      await tester.tap(find.text('LOG IN'));
      await settle(tester);
      expect(find.text('Enter your email ID or contact number'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(api.requests, isEmpty);

      await tester.tap(find.text('OTP'));
      await settle(tester);
      expect(find.text('SEND OTP'), findsOneWidget);
      expect(find.text('Forgot password?'), findsNothing);

      await tester.tap(find.text('PASSWORD'));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Email ID / Contact No'), 'akib@cotrav.co');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Secret1');
      await tester.tap(find.text('LOG IN'));
      await settle(tester);

      expect(api.requests.single.bodyFields, {'login_id': 'akib@cotrav.co', 'password': 'Secret1'});
      expect((await store.read())?.token, 'tok-123');
    });

    testWidgets('shows the server error', (tester) async {
      final api = FakeApi({
        ApiConfig.passwordLogin: {'success': '0', 'error': 'Incorrect Email ID/Contact No or Password!!!'},
      });
      await tester.pumpWidget(app(AuthRepository(client: api.client, store: MemorySessionStore())));
      await settle(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Email ID / Contact No'), 'a@b.co');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'wrong');
      await tester.tap(find.text('LOG IN'));
      await settle(tester);

      expect(find.text('Incorrect Email ID/Contact No or Password!!!'), findsOneWidget);
    });
  });
}
