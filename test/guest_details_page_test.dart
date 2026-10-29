import 'package:cotrav_black_scanner/core/theme/app_theme.dart';
import 'package:cotrav_black_scanner/features/guest/view/guest_details_page.dart';
import 'package:cotrav_black_scanner/features/scanner/data/guest_pass_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primary guest and co-guests render in separate sections', (tester) async {
    final pass = const GuestPassParser().parse(
      '{"event_name":"Founders Night 2026","booking_id":"CTB-1","guest":{"name":"Aarav Mehta","phone":"123"},'
      '"co_guests":[{"name":"Isha Mehta","relation":"Spouse"},{"name":"Kabir Mehta"}]}',
    );

    tester.view.physicalSize = const Size(1170, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: GuestDetailsPage(pass: pass),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Founders Night 2026'), findsOneWidget);
    expect(find.text('PRIMARY'), findsOneWidget);
    expect(find.text('Aarav Mehta'), findsOneWidget);
    expect(find.text('CO-GUEST 1'), findsOneWidget);
    expect(find.text('CO-GUEST 2'), findsOneWidget);

    // Co-guest details are shown without any tap.
    expect(find.text('RELATION'), findsOneWidget);
    expect(find.text('Spouse'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('co-guest section is hidden when there are no co-guests', (tester) async {
    final pass = const GuestPassParser().parse('{"name":"Solo Guest","co_guest":"Not specified"}');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: GuestDetailsPage(pass: pass),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Solo Guest'), findsOneWidget);
    expect(find.textContaining('CO-GUEST'), findsNothing);
    expect(find.textContaining('Co-guest'), findsNothing);
    expect(find.text('Pass Verified'), findsOneWidget);
  });
}
