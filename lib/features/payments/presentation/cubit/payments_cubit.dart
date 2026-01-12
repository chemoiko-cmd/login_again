import 'package:bloc/bloc.dart';
import '../../data/payments_repository.dart';
import '../../domain/payment.dart';
import 'payments_state.dart';

class PaymentsCubit extends Cubit<PaymentsState> {
  final PaymentsRepository repo;
  PaymentsCubit({required this.repo}) : super(PaymentsState.initial());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      // Fetch both pending/unpaid and paid invoices
      final pendingItems = await repo.fetchPayments();
      final historyItems = await repo.fetchPaymentHistory();

      // Combine both lists
      final allItems = [...pendingItems, ...historyItems];

      final providers = await repo.fetchProviders();
      emit(
        state.copyWith(
          loading: false,
          items: allItems,
          providers: providers,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> pay(PaymentItem item) async {
    emit(state.copyWith(processing: true, error: null));
    try {
      await repo.pay(item);
      final updated = state.items.map((p) {
        if (p.id == item.id) {
          return p.copyWith(status: 'paid', paidDate: DateTime.now());
        }
        return p;
      }).toList();
      emit(state.copyWith(processing: false, items: updated));
    } catch (e) {
      emit(state.copyWith(processing: false, error: e.toString()));
    }
  }

  Future<void> payAllPending() async {
    final pending = state.items.where(
      (p) => p.status == 'pending' || p.status == 'overdue',
    );
    emit(state.copyWith(processing: true, error: null));
    try {
      for (final p in pending) {
        await repo.pay(p);
      }
      final updated = state.items
          .map(
            (p) => (p.status == 'pending' || p.status == 'overdue')
                ? p.copyWith(status: 'paid', paidDate: DateTime.now())
                : p,
          )
          .toList();
      emit(state.copyWith(processing: false, items: updated));
    } catch (e) {
      emit(state.copyWith(processing: false, error: e.toString()));
    }
  }

  void selectProvider(int? providerId) {
    emit(state.copyWith(selectedProviderId: providerId));
  }
}
