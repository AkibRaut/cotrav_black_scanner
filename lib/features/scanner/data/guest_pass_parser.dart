import 'dart:convert';

import '../models/guest_pass.dart';

/// Turns guest pass data into a [GuestPass].
///
/// Accepts JSON (plain or base64-encoded) or simple `key: value` lines, and
/// tolerates the common naming variants (`co_guests`, `coGuests`,
/// `companions`, `guests: [...]`, `Co-Guest 1: ...`). Unknown keys are kept
/// and shown as-is, so new fields appear in the UI without code changes.
/// Placeholder values such as "Not specified" or "N/A" are dropped.
///
/// Throws [FormatException] when the data is not a guest pass.
class GuestPassParser {
  const GuestPassParser();

  /// Keys for a person's own name, e.g. `Name`, `Guest Name (Primary)`.
  static final _nameKey = RegExp(r'^(primary|main|lead)?(guest|attendee|visitor)?(full)?name(primary|main|lead)?$');
  static const _bareNameKeys = {'guest', 'primaryguest', 'mainguest', 'leadguest', 'attendee'};
  static const _firstNameKeys = {'firstname', 'fname', 'givenname'};
  static const _lastNameKeys = {'lastname', 'lname', 'surname', 'familyname'};
  static const _primaryKeys = {'guest', 'primaryguest', 'mainguest', 'leadguest', 'guestinfo', 'guestdetails'};

  /// Keys holding co-guests: `co_guests`, `Secondary guest`, `Co-Guest 2`,
  /// `Guest Name (Secondary)`, `Companions`, ...
  static final _coGuestKey = RegExp(
    r'^((co|secondary|second|additional|accompanying|other)guests?|companions?|plusonename|guests?(name)?(secondary|2))'
    r'\d*(names?|details|list)?$',
  );
  static const _guestListKeys = {'guests', 'guestlist', 'travellers', 'travelers'};
  static const _bookingKeys = {'booking', 'bookingdetails', 'reservation', 'stay', 'trip'};
  static const _eventKeys = {'event', 'eventname', 'eventtitle', 'eventdetails', 'eventinfo', 'occasion'};
  static const _eventNameKeys = {'name', 'title', 'eventname', 'eventtitle'};
  static const _eventDetailKeys = {
    'date',
    'time',
    'venue',
    'venueaddress',
    'eventdate',
    'eventtime',
    'eventvenue',
    'eventlocation',
    'startdate',
    'starttime',
    'enddate',
    'endtime',
    'reportingtime',
    'gatesopen',
  };
  static const _plusOneKeys = {'plusone', 'plusonestatus', 'plusones'};
  static const _envelopeKeys = {'data', 'payload', 'result', 'pass', 'rsvp'};
  static const _acronyms = {'id', 'pnr', 'dob', 'otp', 'gst', 'pan', 'uid', 'qr', 'rsvp'};

  /// Values that mean "no data" and must not be shown (compared normalized).
  static const _placeholders = {
    '',
    'notspecified',
    'unspecified',
    'na',
    'none',
    'null',
    'nil',
    'nan',
    'undefined',
    'notavailable',
    'notprovided',
    'notapplicable',
  };

  GuestPass parse(String raw) {
    final map = _unwrap(_decode(raw.trim()));

    final coKey = _findKey(map, _isCoGuestKey);
    final primaryKey = _findKey(map, _primaryKeys.contains);
    final listKey = _findKey(map, _guestListKeys.contains);
    final bookingKey = _findKey(map, _bookingKeys.contains);

    final coGuests = coKey == null ? <Guest>[] : _toGuests(map[coKey]);
    final bookingMap = bookingKey != null && map[bookingKey] is Map
        ? Map<String, dynamic>.from(map[bookingKey] as Map)
        : <String, dynamic>{};

    // The event can sit at the top level or inside the booking object.
    final (eventName, eventFields) = _takeEvent(map) ?? _takeEvent(bookingMap) ?? (null, <GuestField>[]);
    final eventDetails = [...eventFields, ..._takeEventDetails(map), ..._takeEventDetails(bookingMap)];
    final booking = _toFields(bookingMap);

    final Guest primary;
    final Map<String, dynamic> rest;

    if (primaryKey != null && map[primaryKey] is Map) {
      final guestMap = Map<String, dynamic>.from(map[primaryKey] as Map);
      // Co-guests are sometimes nested inside the primary guest object.
      final nestedCoKey = _findKey(guestMap, _isCoGuestKey);
      if (nestedCoKey != null) coGuests.addAll(_toGuests(guestMap.remove(nestedCoKey)));
      primary = _toGuest(guestMap);
      rest = map;
    } else if (listKey != null && map[listKey] is List && (map[listKey] as List).isNotEmpty) {
      final all = _toGuests(map[listKey]);
      if (all.isEmpty) throw const FormatException('No guest details found in this pass.');
      primary = all.first;
      coGuests.insertAll(0, all.skip(1));
      rest = map;
    } else {
      primary = _toGuest(Map.of(map)..removeWhere((k, _) => k == coKey || k == bookingKey));
      rest = const {};
    }

    // Top-level scalars next to an explicit guest object describe the booking.
    booking.addAll(
      _toFields(Map.of(rest)..removeWhere((k, _) => k == coKey || k == primaryKey || k == listKey || k == bookingKey)),
    );

    // "Plus-one: Available" is redundant once the co-guest is listed.
    bool keep(GuestField f) => coGuests.isEmpty || !_plusOneKeys.contains(f.key);

    if (primary.name.isEmpty && primary.fields.isEmpty) {
      throw const FormatException('No guest details found in this pass.');
    }

    return GuestPass(
      eventName: eventName,
      eventDetails: eventDetails,
      primary: Guest(name: primary.name.isEmpty ? 'Guest' : primary.name, fields: primary.fields.where(keep).toList()),
      coGuests: coGuests,
      booking: booking.where(keep).toList(),
    );
  }

  /// Removes the event entry from [map] and returns its name plus any extra
  /// event details (date, venue, ...).
  (String?, List<GuestField>)? _takeEvent(Map<String, dynamic> map) {
    final key = _findKey(map, _eventKeys.contains);
    if (key == null) return null;
    final value = map.remove(key);

    if (value is Map) {
      final eventMap = Map<String, dynamic>.from(value);
      final nameKey = _findKey(eventMap, _eventNameKeys.contains);
      final name = nameKey == null ? null : _stringify(eventMap.remove(nameKey));
      return (name, _toFields(eventMap));
    }
    return (_stringify(value), <GuestField>[]);
  }

  /// Removes date / time / venue entries from [map] and returns them.
  List<GuestField> _takeEventDetails(Map<String, dynamic> map) {
    final keys = map.keys.where((k) => _eventDetailKeys.contains(_norm(k)) && map[k] is! Map).toList();
    return _toFields({for (final k in keys) k: map.remove(k)});
  }

  Map<String, dynamic> _decode(String raw) {
    if (raw.isEmpty) throw const FormatException('Empty QR code.');

    final json = _tryJson(raw) ?? _tryJson(_tryBase64(raw));
    if (json is Map) return Map<String, dynamic>.from(json);
    if (json is List && json.isNotEmpty && json.every((e) => e is Map)) {
      return {'guests': json};
    }

    final kv = _tryKeyValue(raw);
    if (kv != null) return kv;

    throw const FormatException('This QR code is not a guest pass.');
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> map) {
    if (map.length == 1) {
      final only = map.entries.first;
      if (_envelopeKeys.contains(_norm(only.key)) && only.value is Map) {
        return Map<String, dynamic>.from(only.value as Map);
      }
    }
    return map;
  }

  Object? _tryJson(String? source) {
    if (source == null) return null;
    final s = source.trimLeft();
    if (!s.startsWith('{') && !s.startsWith('[')) return null;
    try {
      return jsonDecode(s);
    } on FormatException {
      return null;
    }
  }

  String? _tryBase64(String raw) {
    if (raw.length < 8 || raw.contains(RegExp(r'\s'))) return null;
    try {
      return utf8.decode(base64.decode(base64.normalize(raw)));
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic>? _tryKeyValue(String raw) {
    final result = <String, dynamic>{};
    final coGuests = <String>[];

    for (final line in raw.split(RegExp(r'[\n;|]'))) {
      final match = RegExp(r'^\s*([^:=]+?)\s*[:=]\s*(.+?)\s*$').firstMatch(line);
      if (match == null) continue;
      final key = match.group(1)!;
      final value = match.group(2)!;
      if (_isCoGuestKey(key)) {
        coGuests.add(value);
      } else {
        result.putIfAbsent(key, () => value);
      }
    }
    if (coGuests.isNotEmpty) result['co_guests'] = coGuests.join(',');

    final hasName = result.keys.any((k) => _isNameKey(k) || _firstNameKeys.contains(_norm(k)));
    return hasName ? result : null;
  }

  List<Guest> _toGuests(Object? value) {
    final guests = switch (value) {
      List list => [
        for (final item in list)
          if (item is Map) _toGuest(Map<String, dynamic>.from(item)) else Guest(name: _stringify(item) ?? ''),
      ],
      Map map => [_toGuest(Map<String, dynamic>.from(map))],
      String s => [for (final name in s.split(',')) Guest(name: _stringify(name) ?? '')],
      _ => <Guest>[],
    };
    // "Co-guests: No" / "0" / "Not specified" means there are none.
    return guests
        .where(
          (g) =>
              g.fields.isNotEmpty || (g.name.isNotEmpty && !RegExp(r'^(no|0)$', caseSensitive: false).hasMatch(g.name)),
        )
        .map((g) => g.name.isEmpty ? Guest(name: 'Guest', fields: g.fields) : g)
        .toList();
  }

  Guest _toGuest(Map<String, dynamic> map) {
    String? name;
    String? first;
    String? last;
    final remaining = <String, dynamic>{};

    for (final entry in map.entries) {
      final n = _norm(entry.key);
      final value = entry.value;
      if (name == null && _isNameKey(entry.key) && value is! Map && value is! List) {
        name = _stringify(value) ?? '';
      } else if (first == null && _firstNameKeys.contains(n)) {
        first = _stringify(value);
      } else if (last == null && _lastNameKeys.contains(n)) {
        last = _stringify(value);
      } else {
        remaining[entry.key] = value;
      }
    }

    if (name == null || name.isEmpty) {
      name = [first, last].whereType<String>().join(' ');
    }
    return Guest(name: name, fields: _toFields(remaining));
  }

  List<GuestField> _toFields(Map<String, dynamic> map) {
    return [
      for (final entry in map.entries)
        if (_stringify(entry.value) case final value?)
          GuestField(key: _norm(entry.key), label: _humanize(entry.key), value: value),
    ];
  }

  /// Display text for [value], or null when there is nothing worth showing.
  String? _stringify(Object? value) {
    final text = switch (value) {
      null => null,
      bool b => b ? 'Yes' : 'No',
      List l => l.map(_stringify).whereType<String>().join(', '),
      Map m =>
        m.entries
            .map((e) => (e.key, _stringify(e.value)))
            .where((e) => e.$2 != null)
            .map((e) => '${_humanize('${e.$1}')}: ${e.$2}')
            .join(' · '),
      _ => '$value'.trim(),
    };
    if (text == null || _placeholders.contains(_norm(text))) return null;
    return text;
  }

  /// First key of [map] whose normalized form passes [test].
  String? _findKey(Map<String, dynamic> map, bool Function(String normalized) test) {
    for (final key in map.keys) {
      if (test(_norm(key))) return key;
    }
    return null;
  }

  static bool _isCoGuestKey(String key) => _coGuestKey.hasMatch(_norm(key));

  static bool _isNameKey(String key) {
    final n = _norm(key);
    return _bareNameKeys.contains(n) || _nameKey.hasMatch(n);
  }

  static String _norm(String key) => key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String _humanize(String key) {
    final words = key
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .split(RegExp(r'[\s_\-.]+'))
        .where((w) => w.isNotEmpty);
    return words
        .map((w) {
          final lower = w.toLowerCase();
          if (_acronyms.contains(lower)) return lower.toUpperCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }
}
