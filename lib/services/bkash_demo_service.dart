import 'dart:math';

class BkashPaymentResult {
  final bool success;
  final String message;
  final String transactionId;

  const BkashPaymentResult({
    required this.success,
    required this.message,
    required this.transactionId,
  });
}

class BkashDemoService {
  static const validWallets = [
    '01770618575',
    '01929918378',
    '01770618576',
    '01877722345',
    '01619777282',
    '01619777283',
  ];

  static const insufficientBalanceWallet = '01823074817';
  static const debitBlockedWallet = '01823074818';
  static const validPin = '12121';
  static const validOtp = '123456';

  Future<BkashPaymentResult> pay({
    required String wallet,
    required String pin,
    required String otp,
    required double amount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));

    if (wallet == insufficientBalanceWallet) {
      return const BkashPaymentResult(
        success: false,
        message: 'Payment failed: insufficient balance in sandbox wallet.',
        transactionId: '',
      );
    }
    if (wallet == debitBlockedWallet) {
      return const BkashPaymentResult(
        success: false,
        message: 'Payment failed: wallet is debit blocked in sandbox.',
        transactionId: '',
      );
    }
    if (!validWallets.contains(wallet)) {
      return const BkashPaymentResult(
        success: false,
        message: 'Invalid sandbox wallet number.',
        transactionId: '',
      );
    }
    if (pin != validPin || otp != validOtp) {
      return const BkashPaymentResult(
        success: false,
        message: 'Invalid sandbox PIN/OTP. Use PIN 12121 and OTP 123456.',
        transactionId: '',
      );
    }

    final random = Random();
    final trx = 'TRX${DateTime.now().millisecondsSinceEpoch}${random.nextInt(9)}';
    return BkashPaymentResult(
      success: true,
      message:
          'Sandbox payment success for BDT ${amount.toStringAsFixed(0)} via bKash.',
      transactionId: trx,
    );
  }
}
