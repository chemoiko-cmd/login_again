class PaymentProvider {
  final int id;
  final String name;
  final String code; // e.g., 'stripe', 'flutterwave', 'mpesa'
  final String state; // e.g., 'enabled', 'disabled'
  final String? displayAs; // optional display label

  PaymentProvider({
    required this.id,
    required this.name,
    required this.code,
    required this.state,
    this.displayAs,
  });
}
