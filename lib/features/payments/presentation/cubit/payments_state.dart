import 'package:equatable/equatable.dart';
import '../../../payments/domain/payment.dart';
import '../../../payments/domain/payment_provider.dart';

class PaymentsState extends Equatable {
  final bool loading;
  final List<PaymentItem> items;
  final String? error;
  final bool processing;
  final List<PaymentProvider> providers;
  final int? selectedProviderId;

  const PaymentsState({
    required this.loading,
    required this.items,
    this.error,
    this.processing = false,
    this.providers = const [],
    this.selectedProviderId,
  });

  factory PaymentsState.initial() => const PaymentsState(
    loading: true,
    items: [],
    providers: [],
    selectedProviderId: null,
  );

  PaymentsState copyWith({
    bool? loading,
    List<PaymentItem>? items,
    String? error,
    bool? processing,
    List<PaymentProvider>? providers,
    int? selectedProviderId,
  }) {
    return PaymentsState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
      processing: processing ?? this.processing,
      providers: providers ?? this.providers,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    items,
    error,
    processing,
    providers,
    selectedProviderId,
  ];
}
