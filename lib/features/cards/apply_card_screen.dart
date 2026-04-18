import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/bkash_demo_service.dart';

class ApplyCardScreen extends StatefulWidget {
  const ApplyCardScreen({super.key});

  @override
  State<ApplyCardScreen> createState() => _ApplyCardScreenState();
}

class _ApplyCardScreenState extends State<ApplyCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _walletCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  final _bkashService = BkashDemoService();

  final Map<String, double> _routeFees = const {
    'Mirpur -> DIU Campus': 1200,
    'Dhanmondi -> DIU Campus': 1500,
    'Uttara -> DIU Campus': 1800,
    'Gazipur -> DIU Campus': 2200,
    'Motijheel -> DIU Campus': 1700,
  };

  String? _selectedRoute;
  bool _isPaying = false;
  String _paymentStatus = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _studentIdCtrl.dispose();
    _walletCtrl.dispose();
    _pinCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoute == null) return;

    setState(() {
      _isPaying = true;
      _paymentStatus = '';
    });

    final result = await _bkashService.pay(
      wallet: _walletCtrl.text.trim(),
      pin: _pinCtrl.text.trim(),
      otp: _otpCtrl.text.trim(),
      amount: _routeFees[_selectedRoute]!,
    );

    if (!mounted) return;
    setState(() {
      _isPaying = false;
      _paymentStatus = result.success
          ? '${result.message}\nTransaction: ${result.transactionId}'
          : result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amount = _selectedRoute != null ? _routeFees[_selectedRoute]! : null;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Card')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Card Application Form',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDark ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in your name, student ID, and route. Amount is auto-calculated.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _studentIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter student ID'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRoute,
              decoration: const InputDecoration(
                labelText: 'Route',
                prefixIcon: Icon(Icons.route_rounded),
              ),
              items: _routeFees.keys
                  .map((route) => DropdownMenuItem<String>(
                        value: route,
                        child: Text(route),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedRoute = value),
              validator: (v) => v == null ? 'Please select a route' : null,
            ),
            const SizedBox(height: 16),
            if (amount != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Payable Amount: BDT ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2D3748) : Colors.grey.shade200,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method: bKash Sandbox',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sandbox URL is used for testing integration only.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _walletCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'bKash Wallet Number',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 11) ? 'Enter wallet number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter PIN' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  prefixIcon: Icon(Icons.verified_user_rounded),
                ),
                validator: (v) => (v == null || v.trim().length < 6) ? 'Enter OTP' : null,
              ),
              const SizedBox(height: 14),
              Text(
                'Sandbox credentials loaded:\n'
                'User: ${AppConstants.bkashUsername}\n'
                'App Key: ${AppConstants.bkashAppKey}\n'
                'Base URL: ${AppConstants.bkashBaseSandboxUrl}\n'
                'Test PIN: 12121 | Test OTP: 123456',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isPaying ? null : _handlePayment,
                icon: _isPaying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_balance_wallet_rounded),
                label: Text(_isPaying
                    ? 'Processing...'
                    : 'Pay with bKash Sandbox'),
              ),
              const SizedBox(height: 10),
              if (_paymentStatus.isNotEmpty)
                Text(
                  _paymentStatus,
                  style: TextStyle(
                    color: _paymentStatus.startsWith('Sandbox payment success')
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
