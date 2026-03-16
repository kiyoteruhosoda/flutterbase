import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SplashStatus { loading, done, error }

class SplashState {
  const SplashState({
    this.status = SplashStatus.loading,
    this.errorMessage,
  });

  final SplashStatus status;
  final String? errorMessage;

  SplashState copyWith({
    SplashStatus? status,
    String? errorMessage,
  }) {
    return SplashState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SplashViewModel extends StateNotifier<SplashState> {
  SplashViewModel() : super(const SplashState());

  Future<void> initialize() async {
    state = const SplashState(status: SplashStatus.loading);
    try {
      // TODO: Add actual initialization logic (DB migration, config load, etc.)
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      state = const SplashState(status: SplashStatus.done);
    } catch (e) {
      state = SplashState(
        status: SplashStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final splashViewModelProvider =
    StateNotifierProvider.autoDispose<SplashViewModel, SplashState>(
  (ref) => SplashViewModel(),
);
