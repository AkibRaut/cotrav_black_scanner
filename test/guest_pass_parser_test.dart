import 'dart:convert';

import 'package:cotrav_black_scanner/features/scanner/bloc/scanner_bloc.dart';
import 'package:cotrav_black_scanner/features/scanner/data/guest_pass_parser.dart';
import 'package:cotrav_black_scanner/features/scanner/data/guest_pass_repository.dart';
import 'package:cotrav_black_scanner/features/scanner/data/pass_html_extractor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _passUrl = 'https://cotravblack.co/rsvp-pass.php?token=abc123';

void main() {
  const parser = GuestPassParser();

  group('GuestPassParser', () {
    test('parses guest object with co-guests and booking fields', () {
      final pass = parser.parse(
        jsonEncode({
          'booking_id': 'CTB-1042',
          'hotel': 'Taj Lands End',
          'guest': {'name': 'Aarav Mehta', 'phone': '+91 98200 00000', 'room_no': '1204'},
          'co_guests': [
            {'first_name': 'Isha', 'last_name': 'Mehta', 'relation': 'Spouse'},
            {'name': 'Kabir Mehta', 'age': 8},
          ],
        }),
      );

      expect(pass.primary.name, 'Aarav Mehta');
      expect(pass.primary.initials, 'AM');
      expect(pass.primary.fields.map((f) => f.label), ['Phone', 'Room No']);
      expect(pass.coGuests.map((g) => g.name), ['Isha Mehta', 'Kabir Mehta']);
      expect(pass.booking.map((f) => f.label), ['Booking ID', 'Hotel']);
      expect(pass.totalGuests, 3);
    });

    test('reads the event name, from a string or an event object', () {
      expect(parser.parse('{"event_name":"Annual Gala 2026","name":"A"}').eventName, 'Annual Gala 2026');

      final pass = parser.parse('{"event":{"title":"Leaders Summit","venue":"Jio World"},"guest":{"name":"A"}}');
      expect(pass.eventName, 'Leaders Summit');
      expect(pass.eventDetails.single.value, 'Jio World');
      expect(pass.booking, isEmpty);
      expect(pass.primary.fields, isEmpty);
    });

    test('drops "Not specified" values and empty co-guests', () {
      final pass = parser.parse(
        jsonEncode({
          'name': 'Riya Shah',
          'email': 'Not specified',
          'phone': 'N/A',
          'company': '-',
          'city': 'Pune',
          'co_guest': 'Not specified',
        }),
      );
      expect(pass.primary.fields.map((f) => f.label), ['City']);
      expect(pass.coGuests, isEmpty);

      expect(parser.parse('Name: A\nCo-Guest: No').coGuests, isEmpty);
      expect(parser.parse('{"name":"A","co_guests":[]}').coGuests, isEmpty);
    });

    test('parses flat guest with camelCase co-guest names', () {
      final pass = parser.parse('{"fullName":"Riya Shah","email":"r@x.com","coGuests":["A B","C"]}');
      expect(pass.primary.name, 'Riya Shah');
      expect(pass.coGuests.map((g) => g.name), ['A B', 'C']);
      expect(pass.booking, isEmpty);
    });

    test('treats first entry of a guests list as primary', () {
      final pass = parser.parse('[{"name":"One"},{"name":"Two"}]');
      expect(pass.primary.name, 'One');
      expect(pass.coGuests.single.name, 'Two');
    });

    test('parses base64 encoded JSON', () {
      final pass = parser.parse(base64.encode(utf8.encode('{"data":{"guest_name":"Neel"}}')));
      expect(pass.primary.name, 'Neel');
    });

    test('parses key: value lines with numbered co-guests', () {
      final pass = parser.parse('Event: Diwali Night\nName: Dev Rao\nRoom: 301\nCo-Guest 1: Asha\nCo-Guest 2: Ravi');
      expect(pass.eventName, 'Diwali Night');
      expect(pass.primary.name, 'Dev Rao');
      expect(pass.coGuests.map((g) => g.name), ['Asha', 'Ravi']);
    });

    test('rejects non guest payloads', () {
      expect(() => parser.parse('https://example.com'), throwsFormatException);
      expect(() => parser.parse('{}'), throwsFormatException);
    });
  });

  group('passHtmlToText', () {
    test('turns a pass page into a parsable pass', () {
      const html = '''
        <html><head><title>RSVP Pass | COTRAV BLACK</title><style>.x{}</style></head>
        <body><div class="pass">
          <div class="brand">COTRAV BLACK</div>
          <h2 class="event-name">Founders Night 2026</h2>
          <div class="details">
            <p><strong>Name:</strong> Aarav Mehta</p>
            <div class="row"><span>Phone</span><span>98200 00000</span></div>
            <table><tr><th>Company</th><td>Not specified</td></tr></table>
            <dl><dt>Co-Guest 1</dt><dd>Isha Mehta</dd></dl>
          </div>
        </div></body></html>''';

      final pass = parser.parse(passHtmlToText(html));
      expect(pass.eventName, 'Founders Night 2026');
      expect(pass.primary.name, 'Aarav Mehta');
      expect(pass.primary.fields.map((f) => f.label), contains('Phone'));
      expect(pass.primary.fields.map((f) => f.label), isNot(contains('Company')));
      expect(pass.coGuests.single.name, 'Isha Mehta');
    });
  });

  group('GuestPassRepository', () {
    GuestPassRepository repo(http.Response Function(http.Request) handler) =>
        GuestPassRepository(client: MockClient((r) async => handler(r)));

    test('fetches JSON pass from a Cotrav Black link', () async {
      late Uri requested;
      final pass = await repo((r) {
        requested = r.url;
        return http.Response(
          '{"event_name":"Gala","guest":{"name":"A"}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }).resolve(_passUrl);

      expect(requested.queryParameters['token'], 'abc123');
      expect(pass.eventName, 'Gala');
      expect(pass.primary.name, 'A');
    });

    test('reports a missing pass', () async {
      expect(
        repo((_) => http.Response('<h1>Pass not found</h1>', 404)).resolve(_passUrl),
        throwsA(isA<PassLookupException>().having((e) => e.message, 'message', contains('not found'))),
      );
    });

    test('never contacts other hosts', () async {
      var called = false;
      final r = repo((_) {
        called = true;
        return http.Response('', 200);
      });
      await expectLater(r.resolve('https://evil.example/pass?token=1'), throwsA(isA<PassLookupException>()));
      expect(called, isFalse);
    });

    test('parses inline QR data without network', () async {
      final pass = await repo((_) => throw StateError('no network expected')).resolve('{"name":"Inline"}');
      expect(pass.primary.name, 'Inline');
    });
  });

  group('ScannerBloc', () {
    ScannerBloc bloc({Duration errorDisplay = const Duration(milliseconds: 1800)}) => ScannerBloc(
      repository: GuestPassRepository(client: MockClient((_) async => http.Response('', 404))),
      errorDisplayDuration: errorDisplay,
    );

    test('emits loading then success for a valid pass and ignores further codes', () async {
      final b = bloc();
      final states = <ScannerStatus>[];
      final sub = b.stream.listen((s) => states.add(s.status));
      b
        ..add(const ScannerCodeDetected('{"name":"A"}'))
        ..add(const ScannerCodeDetected('{"name":"B"}'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(states, [ScannerStatus.loading, ScannerStatus.success]);
      expect(b.state.pass!.primary.name, 'A');
      await sub.cancel();
      await b.close();
    });

    test('shows failure then returns to scanning', () async {
      final b = bloc(errorDisplay: const Duration(milliseconds: 10));
      b.add(const ScannerCodeDetected(_passUrl));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(b.state.status, ScannerStatus.failure);
      expect(b.state.error, contains('not found'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(b.state.status, ScannerStatus.scanning);
      await b.close();
    });
  });
}
