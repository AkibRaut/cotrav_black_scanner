part of 'scanner_bloc.dart';

sealed class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

/// The camera read a QR code.
final class ScannerCodeDetected extends ScannerEvent {
  const ScannerCodeDetected(this.raw);

  final String raw;

  @override
  List<Object?> get props => [raw];
}

/// The user is back on the scanner and ready for the next guest.
final class ScannerResumed extends ScannerEvent {
  const ScannerResumed();
}
