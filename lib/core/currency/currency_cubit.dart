import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'currency_repository.dart';

class CurrencyState extends Equatable {
  final bool loading;
  final String? symbol;
  final String position; // 'before' | 'after'
  final String? error;

  const CurrencyState({
    required this.loading,
    this.symbol,
    this.position = 'before',
    this.error,
  });

  factory CurrencyState.initial() => const CurrencyState(loading: true);

  CurrencyState copyWith({
    bool? loading,
    String? symbol,
    String? position,
    String? error,
  }) {
    return CurrencyState(
      loading: loading ?? this.loading,
      symbol: symbol ?? this.symbol,
      position: position ?? this.position,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, symbol, position, error];
}

class CurrencyCubit extends Cubit<CurrencyState> {
  final CurrencyRepository repo;
  CurrencyCubit({required this.repo}) : super(CurrencyState.initial());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final info = await repo.fetchCurrency();
      emit(
        state.copyWith(
          loading: false,
          symbol: info.symbol,
          position: info.position,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void reset() {
    emit(CurrencyState.initial());
  }
}
