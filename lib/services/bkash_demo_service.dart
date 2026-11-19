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
  static const validPin = '12121';
  static const validOtp = '123456';
  static const insufficientBalanceWallet = '01000000001';
  static const debitBlockedWallet = '01000000002';

  Future<BkashPaymentResult> pay({
    required String wallet,
    required String pin,
    required String otp,
    required double amount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));

    final cleanWallet = wallet.trim().replaceAll(RegExp(r'[\s\-]'), '');
    final isValidPhone = RegExp(r'^01[3-9]\d{8}$').hasMatch(cleanWallet);

    if (!isValidPhone && cleanWallet != insufficientBalanceWallet && cleanWallet != debitBlockedWallet) {
      return const BkashPaymentResult(
        success: false,
        message: 'Invalid wallet number. Enter a valid 11-digit mobile number.',
        transactionId: '',
      );
    }

    if (cleanWallet == insufficientBalanceWallet) {
      return const BkashPaymentResult(
        success: false,
        message: 'Payment failed: insufficient balance in sandbox wallet.',
        transactionId: '',
      );
    }
    if (cleanWallet == debitBlockedWallet) {
      return const BkashPaymentResult(
        success: false,
        message: 'Payment failed: wallet is debit blocked in sandbox.',
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
