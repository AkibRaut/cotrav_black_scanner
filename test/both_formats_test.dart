import 'package:cotrav_black_scanner/features/scanner/bloc/scanner_bloc.dart';
import 'package:cotrav_black_scanner/features/scanner/data/guest_pass_repository.dart';
import 'package:cotrav_black_scanner/features/scanner/models/guest_pass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Format 1: the QR carries the pass text itself.
const _textQr = '''COTRAV BLACK RSVP PASS
Guest Name (Primary): Sonali
Email: sonali.magar@cotrav.co
Contact: 8999463315
Plus-one: Available
Secondary guest: Dnyaneshwari
Event: A.R. Rahman — The Wonderment Tour
Date: 01 November 2026
Venue: Jio World Garden, Mumbai''';

/// Format 2: the QR carries a link to the pass page.
const _linkQr =
    'https://cotravblack.co/rsvp-pass.php?token=06a990c0a04dda3592baa17c1356d817501264f3f0a50c6198d221b425c34eb6';

/// Wraps [inner] in the same page shell cotravblack.co serves.
String _page(String title, String inner) =>
    '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>$title | COTRAV BLACK</title>'
    '<style>.pass{}.brand{}.details{}</style></head><body><main class="pass">'
    '<p class="brand">COTRAV BLACK</p>$inner</main></body></html>';

final _pageVariants = {
  'label lines with <br>': _page(
    'RSVP Pass',
    '<h1>RSVP Pass</h1><div class="details">Guest Name (Primary): Sonali<br>'
        'Email: sonali.magar@cotrav.co<br>Contact: 8999463315<br>Plus-one: Available<br>'
        'Secondary guest: Dnyaneshwari<br>Event: A.R. Rahman — The Wonderment Tour<br>'
        'Date: 01 November 2026<br>Venue: Jio World Garden, Mumbai</div><small>Show this pass at entry</small>',
  ),
  'bold labels, event as heading': _page(
    'A.R. Rahman — The Wonderment Tour',
    '<h1>A.R. Rahman — The Wonderment Tour</h1><div class="details">'
        '<p><strong>Guest Name (Primary):</strong> Sonali</p>'
        '<p><strong>Email:</strong> sonali.magar@cotrav.co</p>'
        '<p><strong>Contact:</strong> 8999463315</p>'
        '<p><strong>Plus-one:</strong> Available</p>'
        '<p><strong>Secondary guest:</strong> Dnyaneshwari</p>'
        '<p><strong>Date:</strong> 01 November 2026</p>'
        '<p><strong>Venue:</strong> Jio World Garden, Mumbai</p></div>',
  ),
  'label / value spans': _page(
    'RSVP Pass',
    '<div class="event-title">A.R. Rahman — The Wonderment Tour</div><div class="details">'
        '<div><span>Guest Name (Primary)</span><span>Sonali</span></div>'
        '<div><span>Email</span><span>sonali.magar@cotrav.co</span></div>'
        '<div><span>Contact</span><span>8999463315</span></div>'
        '<div><span>Secondary guest</span><span>Dnyaneshwari</span></div>'
        '<div><span>Date</span><span>01 November 2026</span></div>'
        '<div><span>Venue</span><span>Jio World Garden, Mumbai</span></div></div>',
  ),
  'table': _page(
    'RSVP Pass',
    '<h1>RSVP Pass</h1><table>'
        '<tr><th>Event</th><td>A.R. Rahman — The Wonderment Tour</td></tr>'
        '<tr><th>Guest Name (Primary)</th><td>Sonali</td></tr>'
        '<tr><th>Email</th><td>sonali.magar@cotrav.co</td></tr>'
        '<tr><th>Contact</th><td>8999463315</td></tr>'
        '<tr><th>Secondary guest</th><td>Dnyaneshwari</td></tr>'
        '<tr><th>Date</th><td>01 November 2026</td></tr>'
        '<tr><th>Venue</th><td>Jio World Garden, Mumbai</td></tr></table>',
  ),
};

void _expectSonaliPass(GuestPass pass) {
  expect(pass.eventName, 'A.R. Rahman — The Wonderment Tour');
  expect(pass.eventDetails.map((f) => f.value), ['01 November 2026', 'Jio World Garden, Mumbai']);
  expect(pass.primary.name, 'Sonali');
  expect(
    {for (final f in pass.primary.fields) f.label: f.value},
    {'Email': 'sonali.magar@cotrav.co', 'Contact': '8999463315'},
  );
  expect(pass.coGuests.map((g) => g.name), ['Dnyaneshwari']);
}

GuestPassRepository _repo(String body, {int status = 200}) => GuestPassRepository(
  client: MockClient((_) async => http.Response(body, status, headers: {'content-type': 'text/html; charset=UTF-8'})),
);

Future<ScannerState> _scan(GuestPassRepository repo, String raw) async {
  final bloc = ScannerBloc(repository: repo);
  bloc.add(ScannerCodeDetected(raw));
  final state = await bloc.stream.firstWhere((s) => s.status != ScannerStatus.loading);
  await bloc.close();
  return state;
}

void main() {
  test('format 1: text QR is read without any network call', () async {
    final repo = GuestPassRepository(client: MockClient((_) => throw StateError('no network expected')));
    final state = await _scan(repo, _textQr);
    expect(state.status, ScannerStatus.success);
    _expectSonaliPass(state.pass!);
  });

  group('format 2: link QR fetches the pass page', () {
    for (final MapEntry(key: name, value: html) in _pageVariants.entries) {
      test(name, () async {
        final state = await _scan(_repo(html), _linkQr);
        expect(state.status, ScannerStatus.success, reason: state.error);
        _expectSonaliPass(state.pass!);
      });
    }

    test('JSON response', () async {
      final repo = GuestPassRepository(
        client: MockClient(
          (_) async => http.Response(
            '{"event":"A.R. Rahman — The Wonderment Tour","date":"01 November 2026",'
            '"venue":"Jio World Garden, Mumbai","guest_name":"Sonali","email":"sonali.magar@cotrav.co",'
            '"contact":"8999463315","plus_one":"Available","secondary_guest":"Dnyaneshwari"}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final state = await _scan(repo, _linkQr);
      expect(state.status, ScannerStatus.success, reason: state.error);
      _expectSonaliPass(state.pass!);
    });

    const notFoundPage =
        '<!doctype html><html><head><title>Pass not found | COTRAV BLACK</title></head><body>'
        '<main class="pass"><p class="brand">COTRAV BLACK</p><h1>Pass not found</h1>'
        '<p>This QR pass is invalid or is no longer available.</p></main></body></html>';

    test('expired token (404) says pass not found', () async {
      final state = await _scan(_repo(notFoundPage, status: 404), _linkQr);
      expect(state.status, ScannerStatus.failure);
      expect(state.error, 'Pass not found or no longer available.');
    });

    test('not-found page served with 200 still says pass not found', () async {
      final state = await _scan(_repo(notFoundPage), _linkQr);
      expect(state.error, 'Pass not found or no longer available.');
    });
  });
}
