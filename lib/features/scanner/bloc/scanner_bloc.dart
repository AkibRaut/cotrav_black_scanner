import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/guest_pass_repository.dart';
import '../models/guest_pass.dart';

part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  ScannerBloc({
    required this._repository,
    this.errorDisplayDuration = const Duration(milliseconds: 1800),
    this.rejectCooldown = const Duration(seconds: 4),
  }) : super(const ScannerState()) {
    on<ScannerCodeDetected>(_onCodeDetected);
    on<ScannerResumed>(_onResumed);
  }

  final GuestPassRepository _repository;

  /// How long an error stays on screen before scanning resumes.
  final Duration errorDisplayDuration;

  /// The same invalid code is ignored for this long, so a bad QR held in
  /// front of the camera doesn't flash the error over and over.
  final Duration rejectCooldown;

  String? _lastRejected;
  DateTime _lastRejectedAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _onCodeDetected(ScannerCodeDetected event, Emitter<ScannerState> emit) async {
    // The camera fires many frames per second; only the first one counts.
    if (state.status != ScannerStatus.scanning) return;
    if (event.raw == _lastRejected && DateTime.now().difference(_lastRejectedAt) < rejectCooldown) {
      return;
    }

    emit(const ScannerState(status: ScannerStatus.loading));
    try {
      final pass = await _repository.resolve(event.raw);
      emit(ScannerState(status: ScannerStatus.success, pass: pass));
    } on Exception catch (e) {
      _lastRejected = event.raw;
      _lastRejectedAt = DateTime.now();
      final message = switch (e) {
        FormatException(:final message) => message,
        PassLookupException(:final message) => message,
        _ => 'Could not read this pass.',
      };
      final failure = ScannerState(status: ScannerStatus.failure, error: message);
      emit(failure);

      await Future<void>.delayed(errorDisplayDuration);
      if (state == failure) emit(const ScannerState());
    }
  }

  void _onResumed(ScannerResumed event, Emitter<ScannerState> emit) {
    emit(const ScannerState());
  }

  @override
  Future<void> close() {
    _repository.close();
    return super.close();
  }
}
