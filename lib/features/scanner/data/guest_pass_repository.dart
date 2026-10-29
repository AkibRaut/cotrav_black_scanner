import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/guest_pass.dart';
import 'guest_pass_parser.dart';
import 'pass_html_extractor.dart';

/// A pass could not be loaded; [message] is shown to the scanner operator.
class PassLookupException implements Exception {
  const PassLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resolves a scanned QR value into a [GuestPass].
///
/// The QR either carries the pass data itself, or a link such as
/// `https://cotravblack.co/rsvp-pass.php?token=...`, in which case the pass
/// is fetched from the server. Only [allowedHosts] are contacted, so a random
/// QR code can't make the app load arbitrary sites.
class GuestPassRepository {
  GuestPassRepository({
    http.Client? client,
    this._parser = const GuestPassParser(),
    this.allowedHosts = const {'cotravblack.co', 'www.cotravblack.co'},
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  // One shared client keeps the HTTPS connection alive between scans.
  final http.Client _client;
  final GuestPassParser _parser;
  final Set<String> allowedHosts;
  final Duration timeout;

  Future<GuestPass> resolve(String raw) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      return _parser.parse(raw);
    }
    if (!allowedHosts.contains(uri.host.toLowerCase())) {
      throw const PassLookupException('This QR code is not a Cotrav Black pass.');
    }

    final http.Response response;
    try {
      response = await _client
          .get(uri.replace(scheme: 'https'), headers: const {'Accept': 'application/json, text/html;q=0.9'})
          .timeout(timeout);
    } on TimeoutException {
      throw const PassLookupException('Server took too long. Check the connection and try again.');
    } on http.ClientException {
      throw const PassLookupException('No internet connection.');
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 404 || 410:
        throw const PassLookupException('Pass not found or no longer available.');
      default:
        throw PassLookupException('Could not load pass (error ${response.statusCode}).');
    }

    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    final contentType = response.headers['content-type'] ?? '';
    final isJson = contentType.contains('json') || RegExp(r'^\s*[\[{]').hasMatch(body);

    final text = isJson ? body : passHtmlToText(body);
    try {
      return _parser.parse(text);
    } on FormatException {
      if (passMissingText.hasMatch(text)) {
        throw const PassLookupException('Pass not found or no longer available.');
      }
      throw const PassLookupException('This pass has no guest details.');
    }
  }

  void close() => _client.close();
}
