import 'package:flutter/material.dart';

/// Picks an icon for a field from its normalized key.
IconData iconForField(String key) {
  bool has(List<String> parts) => parts.any(key.contains);

  if (has(['phone', 'mobile', 'contact'])) return Icons.phone_rounded;
  if (has(['plusone'])) return Icons.person_add_alt_1_rounded;
  if (has(['email', 'mail'])) return Icons.alternate_email_rounded;
  if (has(['checkin', 'arrival'])) return Icons.login_rounded;
  if (has(['checkout', 'departure'])) return Icons.logout_rounded;
  if (has(['room', 'bed'])) return Icons.king_bed_rounded;
  if (has(['hotel', 'property'])) return Icons.apartment_rounded;
  if (has(['booking', 'reservation', 'pnr', 'confirmation', 'ticket'])) {
    return Icons.confirmation_number_rounded;
  }
  if (has(['passport', 'aadhaar', 'aadhar', 'pan', 'idtype', 'idnumber', 'idno', 'document'])) {
    return Icons.badge_rounded;
  }
  if (has(['dob', 'birth', 'age'])) return Icons.cake_rounded;
  if (has(['gender', 'sex'])) return Icons.wc_rounded;
  if (has(['nationality', 'country'])) return Icons.flag_rounded;
  if (has(['venue', 'address', 'city', 'state', 'location', 'pincode', 'zip'])) {
    return Icons.location_on_rounded;
  }
  if (has(['company', 'organization', 'organisation', 'corporate', 'employee'])) {
    return Icons.business_center_rounded;
  }
  if (has(['relation'])) return Icons.people_alt_rounded;
  if (has(['date', 'time'])) return Icons.event_rounded;
  if (has(['flight', 'airline'])) return Icons.flight_rounded;
  if (has(['meal', 'food', 'diet'])) return Icons.restaurant_rounded;
  if (has(['amount', 'price', 'paid', 'payment'])) return Icons.payments_rounded;
  if (has(['adult', 'child', 'pax', 'count'])) return Icons.groups_rounded;
  if (has(['id'])) return Icons.tag_rounded;
  return Icons.info_outline_rounded;
}
