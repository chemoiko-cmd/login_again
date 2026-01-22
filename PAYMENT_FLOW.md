# Payment Transaction Flow

This document describes the new payment transaction flow implemented for invoice payments, following a realistic e-commerce pattern with two-step payment processing.

## Overview

The payment flow follows these steps:
1. **Invoice Selection** - User selects one or more invoices to pay
2. **Payment Method Selection** - User chooses payment provider and payment method
3. **Payment Processing** - System creates payment transaction and processes it
4. **Confirmation** - User sees payment confirmation with details

## API Endpoints

### 0. Get Payment Providers with Methods

Fetches all available payment providers along with their payment methods in a single call.

**Endpoint:** `GET /rental/api/v1/payment/providers`

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": null,
  "result": {
    "providers": [
      {
        "provider_id": 6,
        "provider_code": "demo",
        "provider_name": "Demo",
        "provider_state": "test",
        "company_id": 1,
        "payment_method_id": 212,
        "payment_code": "demo",
        "payment_method_name": "Demo"
      },
      {
        "provider_id": 15,
        "provider_code": "custom",
        "provider_name": "Wire Transfer",
        "provider_state": "enabled",
        "company_id": 1,
        "payment_method_id": 213,
        "payment_code": "wire_transfer",
        "payment_method_name": "Wire Transfer"
      }
    ]
  }
}
```

**Benefits:**
- Single API call to get both providers and methods
- Reduced latency and network requests
- Efficient caching of provider-method combinations
- No need for separate method lookup per provider

### 1. Create Payment Transaction

Creates a new payment transaction record linked to invoice(s).

**Endpoint:** `/web/dataset/call_kw`

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "call",
  "params": {
    "model": "payment.transaction",
    "method": "create",
    "args": [
      {
        "amount": 82000,
        "currency_id": 43,
        "partner_id": 53,
        "provider_id": 6,
        "payment_method_id": 212,
        "invoice_ids": [[6, 0, [60]]],
        "operation": "online_direct"
      }
    ],
    "kwargs": {}
  },
  "id": 4
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": 26  // transaction ID
}
```

### 2. Set Payment Transaction as Done

Marks the payment transaction as completed (for demo/test payments).

**Endpoint:** `/web/dataset/call_kw`

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "call",
  "params": {
    "model": "payment.transaction",
    "method": "action_demo_set_done",
    "args": [[26]],
    "kwargs": {}
  },
  "id": 5
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": true
}
```

## New Files Created

### Domain Models

1. **`payment_transaction.dart`** - Payment transaction model
   - Represents a payment transaction with invoice links
   - Handles serialization/deserialization for API calls

2. **`payment_method.dart`** - Payment method model
   - Represents available payment methods (card, bank transfer, mobile money, etc.)

3. **`invoice.dart`** - Invoice model
   - Complete invoice details including amounts, dates, and payment state
   - Helper properties for status determination (isPaid, isOverdue)

4. **`provider_with_method.dart`** - Combined provider and method model
   - Represents the combined data structure from the new API
   - Includes conversion methods to separate Provider and Method objects
   - `PaymentProvidersResponse` - Parses and manages the API response
   - HelprovidersWithMethods()` - Get providers with methods from `/rental/api/v1/payment/providers`
- `fetchProviders()` - Get unique providers list (uses fetchProvidersWithMethods internally)
- `fetchPaymentMethods(int providerId)` - Get payment methods for a provider (cached from initial fetch)
- `fetchInvoice(int invoiceId)` - Get single invoice details
- `fetchInvoicesByNames(List<String> invoiceNames)` - Get multiple invoices by name
- `createPaymentTransaction(PaymentTransaction transaction)` - Create payment transaction
- `setPaymentTransactionDone(int transactionId)` - Mark transaction as done
- `processPayment(...)` - Complete two-step payment flow

**Key Improvements:**
- Single API call fetches all provider-method combinations
- Results are cached and reused for subsequent requests
- No separate API calls needed when selecting payment methods
- Efficient data structure with helper methods for filtering and grouping
- `fetchPaymentMethods(int providerId)` - Get available payment methods for a provider
- `fetchInvoice(int invoiceId)` - Get single invoice details
- `fetchInvoicesByNames(List<String> invoiceNames)` - Get multiple invoices by name
- `createPaymentTransaction(PaymentTransaction transaction)` - Create payment transaction
- `setPaymentTransactionDone(int transactionId)` - Mark transaction as done
- `processPayment(...)` - Complete two-step payment flow

### UI Screens

1. **`payment_method_selection_screen.dart`**
   - Fetches providers and methods on load using repository
   - Displays available payment providers
   - Shows cached payment methods for selected provider (no additional API call)
   - Allows user to select payment method
   - Loading states during initial data fetch

2. **`payment_processing_screen.dart`**
   - Shows payment processing animation
   - Displays payment summary
   - Handles payment success/failure
   - Auto-navigates to confirmation on success

3. **`invoice_checkout_screen.dart`**
   - Main checkout screen
   - Shows invoice list with amounts
   - Payment method selection
   - Payment summary with total
   - "Pay Now" button to proceed

## User Flow

### From Payments List

1. User sees list of pending invoices in Payments tab
2. User taps "Pay Now" on any invoice
3. App navigates to **InvoiceCheckoutScreen**
4. User selects payment method (if not already selected)
5. User reviews invoice details and total amount
6. User taps "Pay [amount]" button
7. App navigates to **PaymentProcessingScreen**
8. Processing screen creates payment transaction
9. Processing screen sets transaction as done
10. App navigates to **PaymentConfirmationScreen**
11. User sees success message with payment details
12. User can download receipt or return to payments list

### Pay All Flow

1. User sees total amount due on Payments tab
2. User taps "Pay All" button
3. App navigates to **InvoiceCheckoutScreen** with all pending invoices
4. Flow continues from step 4 above

## Code Integration Example

### From Payments Page

```dart
// Single invoice payment
TextButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoiceCheckoutScreen(
          invoiceNames: [invoiceId],
        ),
      ),
    );
  },
  child: const Text('Pay Now'),
)

// Multiple invoice payment
ElevatedButton(
  onPressed: () {
    final invoiceNames = pendingInvoices.map((p) => p.id).toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoiceCheckoutScreen(
          invoiceNames: invoiceNames,
        ),
      ),
    );
  },
  child: const Text('Pay All'),
)
```

### Direct API Usage

```dart
final repo = PaymentsRepository(
  apiClient: apiClient,
  authCubit: authCubit,
);Fetch providers with methods (new API)
final response = await repo.fetchProvidersWithMethods();
print('Total combinations: ${response.providers.length}');

// Get unique providers
final providers = response.getUniqueProviders();

// Get methods for a specific provider
final methods = response.getMethodsForProvider(6);

// 

// Process payment
final success = await repo.processPayment(
  amount: 82000,
  currencyId: 43,
  partnerId: 53,
  providerId: 6,
  paymentMethodId: 212,
  invoiceIds: [60],
);
```

## Features

### User Experience
- ✅ Clean, modern UI following e-commerce patterns
- ✅ Progress indication during payment processing
- ✅ Clear payment summary before confirmation
- ✅ Payment method selection with provider logos
- ✅ Invoice grouping for bulk payments
- ✅ Success/failure feedback with animations
- ✅ Payment receipt download (placeholder)

### Technical
- ✅ Two-step payment transaction flow
- ✅ Proper error handling
- ✅ Loading states and animations
- ✅ Null-safe Dart code
- ✅ Repository pattern for API calls
- ✅ Clean separation of concerns
- ✅ Reusable components

## Future Enhancements

1. **Real Payment Integrations**
   - Integrate with Stripe, PayPal, M-Pesa, etc.
   - Handle payment callbacks and webhooks
   - Support 3D Secure authentication

2. **Payment Methods**
   - Saved payment methods
   - Card tokenization
   - Payment method management

3. **Receipts**
   - PDF receipt generation
   - Email receipts
   - Receipt history

4. **Payment Plans**
   - Installment payments
   - Recurring payments
   - Auto-pay setup

5. **Enhanced Features**
   - Payment reminders
   - Late fee calculations
   - Partial payments
   - Refunds and reversals

## Testing

To test the payment flow:

1. Ensure you have pending invoices in the system
2. Navigate to Payments tab
3. Select "Pay Now" on an invoice
4. Choose a payment provider and method
5. Complete the payment flow
6. Verify the invoice status changes to "paid"

For demo/test mode:
- Select a provider with code "demo" or state "test"
- Payment will be simulated without real transaction processing
