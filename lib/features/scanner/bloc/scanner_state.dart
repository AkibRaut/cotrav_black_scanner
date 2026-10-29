part of 'scanner_bloc.dart';

enum ScannerStatus { scanning, loading, success, failure }

final class ScannerState extends Equatable {
  const ScannerState({this.status = ScannerStatus.scanning, this.pass, this.error});

  final ScannerStatus status;
  final GuestPass? pass;
  final String? error;

  @override
  List<Object?> get props => [status, pass, error];
}
