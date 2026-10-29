import 'package:cotrav_black_scanner/core/theme/app_theme.dart';
import 'package:cotrav_black_scanner/features/guest/view/guest_details_page.dart';
import 'package:cotrav_black_scanner/features/scanner/data/guest_pass_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exact text from a real Cotrav Black RSVP pass QR.
const _realPass = '''COTRAV BLACK RSVP PASS
Guest Name (Primary): Sonali
Email: sonali.magar@cotrav.co
Contact: 8999463315
Plus-one: Available
Secondary guest: Dnyaneshwari
Event: A.R. Rahman — The Wonderment Tour
Date: 01 November 2026
Venue: Jio World Garden, Mumbai''';

void main() {
  const parser = GuestPassParser();

  test('parses the real Cotrav Black RSVP pass', () {
    final pass = parser.parse(_realPass);

    expect(pass.eventName, 'A.R. Rahman — The Wonderment Tour');
    expect(
      {for (final f in pass.eventDetails) f.label: f.value},
      {'Date': '01 November 2026', 'Venue': 'Jio World Garden, Mumbai'},
    );
    expect(pass.primary.name, 'Sonali');
    expect(
      {for (final f in pass.primary.fields) f.label: f.value},
      {'Email': 'sonali.magar@cotrav.co', 'Contact': '8999463315'},
    );
    expect(pass.coGuests.map((g) => g.name), ['Dnyaneshwari']);
    expect(pass.booking, isEmpty);
  });

  test('real pass without a plus-one shows no co-guest', () {
    final pass = parser.parse(
      _realPass
          .replaceFirst('Plus-one: Available', 'Plus-one: Not available')
          .replaceFirst('Secondary guest: Dnyaneshwari', 'Secondary guest: Not specified'),
    );

    expect(pass.coGuests, isEmpty);
    expect(pass.primary.fields.map((f) => f.label), ['Email', 'Contact']);
  });

  testWidgets('real pass shows event on top, primary and co-guest separately', (tester) async {
    tester.view.physicalSize = const Size(1170, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: GuestDetailsPage(pass: parser.parse(_realPass)),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    final eventTop = tester.getTopLeft(find.text('A.R. Rahman — The Wonderment Tour')).dy;
    expect(eventTop, lessThan(tester.getTopLeft(find.text('Sonali')).dy));
    expect(find.text('01 November 2026'), findsOneWidget);
    expect(find.text('Jio World Garden, Mumbai'), findsOneWidget);
    expect(find.text('PRIMARY'), findsOneWidget);
    expect(find.text('CO-GUEST 1'), findsOneWidget);
    expect(find.text('Dnyaneshwari'), findsOneWidget);
    expect(find.textContaining('Plus'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
