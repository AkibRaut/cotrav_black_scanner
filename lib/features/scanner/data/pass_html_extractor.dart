import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Flattens a pass web page into `Label: Value` lines that
/// [GuestPassParser] understands.
///
/// Handles `<dl>` lists, two-cell table rows, `<b>Label:</b> value` text and
/// elements with exactly a label child and a value child. Anything with
/// "event" in its class or id becomes the event name.
String passHtmlToText(String source) {
  final document = html_parser.parse(source);
  document.querySelectorAll('script, style, noscript, svg').forEach((e) => e.remove());
  final body = document.body;
  if (body == null) return '';

  final lines = <String>[];

  final event = body
      .querySelectorAll('[class*="event"], [id*="event"]')
      .map(_text)
      .firstWhere((t) => t.isNotEmpty && t.length <= 120 && !t.contains(':'), orElse: () => '');
  if (event.isNotEmpty) lines.add('Event: $event');

  // A heading that isn't generic ("RSVP Pass", "COTRAV BLACK") is likely the
  // event title. Added last so an explicit "Event:" line wins.
  final heading = body
      .querySelectorAll('h1, h2')
      .map(_text)
      .firstWhere(
        (t) => t.isNotEmpty && t.length <= 120 && !t.contains(':') && !_genericHeading.hasMatch(t),
        orElse: () => '',
      );

  for (final dl in body.querySelectorAll('dl')) {
    String? label;
    for (final child in dl.children) {
      if (child.localName == 'dt') label = _text(child);
      if (child.localName == 'dd' && label != null) lines.add('$label: ${_text(child)}');
    }
    dl.remove();
  }

  for (final row in body.querySelectorAll('tr')) {
    final cells = row.children.where((c) => c.localName == 'td' || c.localName == 'th').toList();
    if (cells.length == 2) lines.add('${_text(cells[0])}: ${_text(cells[1])}');
    row.remove();
  }

  // <div><span>Name</span><span>John</span></div> style label/value pairs.
  for (final element in body.querySelectorAll('div, p, li')) {
    final kids = element.children;
    if (kids.length != 2 || kids.any((k) => k.children.isNotEmpty)) continue;
    if (element.nodes.any((n) => n is Text && n.text.trim().isNotEmpty)) continue;
    final label = _text(kids[0]).replaceAll(RegExp(r':\s*$'), '');
    if (label.isNotEmpty && label.length <= 40 && !label.contains(':')) {
      lines.add('$label: ${_text(kids[1])}');
      element.remove();
    }
  }

  final buffer = StringBuffer();
  _writeText(body, buffer);
  lines.addAll(buffer.toString().split('\n'));
  if (heading.isNotEmpty) lines.add('Event: $heading');

  return lines.map((l) => l.trim()).where((l) => l.isNotEmpty).join('\n');
}

final _genericHeading = RegExp(
  r'\b(pass|rsvp|cotrav|ticket|invitation|welcome|not found|invalid)\b',
  caseSensitive: false,
);

/// Text of pages that say the pass doesn't exist, even when served with 200.
final passMissingText = RegExp(
  r'pass not found|invalid or is no longer available|no longer available|invalid (qr|pass|token)|expired',
  caseSensitive: false,
);

const _blockTags = {
  'address', 'article', 'aside', 'br', 'dd', 'div', 'dl', 'dt', 'footer', 'h1', 'h2', 'h3', 'h4', //
  'h5', 'h6', 'header', 'hr', 'li', 'main', 'nav', 'ol', 'p', 'section', 'table', 'tr', 'ul',
};

void _writeText(Node node, StringBuffer out) {
  for (final child in node.nodes) {
    if (child is Text) {
      out.write(child.text.replaceAll(RegExp(r'\s+'), ' '));
    } else if (child is Element) {
      final block = _blockTags.contains(child.localName);
      if (block) out.write('\n');
      _writeText(child, out);
      if (block) out.write('\n');
    }
  }
}

String _text(Element e) => e.text.replaceAll(RegExp(r'\s+'), ' ').trim();
