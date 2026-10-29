import 'package:equatable/equatable.dart';

/// A single labelled piece of information read from the QR code.
class GuestField extends Equatable {
  const GuestField({required this.key, required this.label, required this.value});

  /// Normalized key (lowercase, alphanumeric only), used to pick an icon.
  final String key;
  final String label;
  final String value;

  @override
  List<Object?> get props => [key, label, value];
}

class Guest extends Equatable {
  const Guest({required this.name, this.fields = const []});

  final String name;
  final List<GuestField> fields;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  List<Object?> get props => [name, fields];
}

/// Everything decoded from one scanned guest QR code.
class GuestPass extends Equatable {
  const GuestPass({
    required this.primary,
    this.eventName,
    this.eventDetails = const [],
    this.coGuests = const [],
    this.booking = const [],
  });

  /// Name of the event this pass is for, shown at the top of the pass.
  final String? eventName;

  /// Date, time, venue and other details about the event itself.
  final List<GuestField> eventDetails;

  final Guest primary;
  final List<Guest> coGuests;

  /// Stay / reservation level details that don't belong to one guest.
  final List<GuestField> booking;

  int get totalGuests => 1 + coGuests.length;

  @override
  List<Object?> get props => [eventName, eventDetails, primary, coGuests, booking];
}
