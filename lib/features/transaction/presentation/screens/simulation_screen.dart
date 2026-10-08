import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/services/in_app_notification_service.dart';
import '../../../payments/data/payment_api_service.dart';
import '../../../wallet/data/wallet_api_service.dart';
import 'deposit_khqr_screen.dart';

class CambodianBank {
  final String name;
  final String code;
  final String example;
  final int minDigits;
  final int maxDigits;
  final Color brandColor;

  const CambodianBank({
    required this.name,
    required this.code,
    required this.example,
    required this.minDigits,
    required this.maxDigits,
    required this.brandColor,
  });
}

const List<CambodianBank> kCambodianBanks = [
  CambodianBank(
    name: 'ABA Bank',
    code: 'ABA',
    example: '001 234 567 (9 digits)',
    minDigits: 9,
    maxDigits: 9,
    brandColor: Color(0xFF004B87),
  ),
  CambodianBank(
    name: 'ACLEDA Bank',
    code: 'ACLEDA',
    example: '0100 2345 6789 (10-14 digits)',
    minDigits: 10,
    maxDigits: 14,
    brandColor: Color(0xFF1E3A8A),
  ),
  CambodianBank(
    name: 'Canadia Bank',
    code: 'CANADIA',
    example: '001 123 456 789 (10-13 digits)',
    minDigits: 10,
    maxDigits: 13,
    brandColor: Color(0xFFDC2626),
  ),
  CambodianBank(
    name: 'Wing Bank',
    code: 'WING',
    example: '012 345 678 (8-10 digits)',
    minDigits: 8,
    maxDigits: 10,
    brandColor: Color(0xFF65A30D),
  ),
  CambodianBank(
    name: 'Sathapana Bank',
    code: 'SPN',
    example: '123 456 789 (9-13 digits)',
    minDigits: 9,
    maxDigits: 13,
    brandColor: Color(0xFF0F766E),
  ),
  CambodianBank(
    name: 'Chip Mong Bank',
    code: 'CMB',
    example: '888 123 456 (9-12 digits)',
    minDigits: 9,
    maxDigits: 12,
    brandColor: Color(0xFFE11D48),
  ),
  CambodianBank(
    name: 'Prince Bank',
    code: 'PRINCE',
    example: '777 234 567 (9-12 digits)',
    minDigits: 9,
    maxDigits: 12,
    brandColor: Color(0xFF7C3AED),
  ),
];

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({
    super.key,
    required this.title,
    required this.button,
    required this.positive,
  });

  final String title;
  final String button;
  final bool positive;

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController(text: '001234567');
  final _accountNameController = TextEditingController(text: 'SOKHA CHAN');
  final _pinController = TextEditingController();

  CambodianBank _selectedBank = kCambodianBanks[0];
  bool _obscurePin = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = AuthState.instance.currentUser;
    if (user != null && user.fullName.isNotEmpty) {
      _accountNameController.text = user.fullName.toUpperCase();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String? _getAccountValidationError() {
    if (widget.positive) return null;
    final raw = _accountNumberController.text.replaceAll(RegExp(r'[\s\-]'), '');
    if (raw.isEmpty) return 'Account number is required.';
    if (!RegExp(r'^\d+$').hasMatch(raw)) return 'Account number must contain only numbers.';
    if (_selectedBank.minDigits == _selectedBank.maxDigits) {
      if (raw.length != _selectedBank.minDigits) {
        return '${_selectedBank.name} account must be ${_selectedBank.minDigits} digits.';
      }
    } else {
      if (raw.length < _selectedBank.minDigits || raw.length > _selectedBank.maxDigits) {
        return '${_selectedBank.name} account must be ${_selectedBank.minDigits}-${_selectedBank.maxDigits} digits.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final available = WalletApiService.instance.wallet.effectiveAvailable;
    final accountError = _getAccountValidationError();

    final chips = widget.positive
        ? ['\$50', '\$100', '\$500']
        : ['\$20', '\$50', '\$100', 'MAX'];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.positive
                  ? 'Instantly add funds to your NovaPay wallet'
                  : 'Available balance: \$${available.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                labelText: 'Amount',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: chips.map((option) {
                return ActionChip(
                  label: Text(option),
                  onPressed: () {
                    if (option == 'MAX') {
                      final maxVal = available > 1.50 ? available - 1.50 : available;
                      _amountController.text =
                          maxVal > 0 ? maxVal.toStringAsFixed(2) : '0.00';
                    } else {
                      _amountController.text = option.substring(1);
                    }
                    setState(() {});
                  },
                );
              }).toList(),
            ),

            if (!widget.positive) ...[
              const SizedBox(height: 24),
              const Text(
                'DESTINATION CAMBODIAN BANK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),

              // Bank Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CambodianBank>(
                    value: _selectedBank,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(16),
                    items: kCambodianBanks.map((bank) {
                      return DropdownMenuItem<CambodianBank>(
                        value: bank,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: bank.brandColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              bank.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              '(${bank.code})',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (bank) {
                      if (bank != null) {
                        setState(() => _selectedBank = bank);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Account Number Input
              TextField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: '${_selectedBank.name} Account Number',
                  hintText: _selectedBank.example,
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  errorText: accountError,
                ),
              ),
              const SizedBox(height: 14),

              // Account Holder Name
              TextField(
                controller: _accountNameController,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  hintText: 'e.g. SOKHA CHAN',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),

              // Transaction PIN
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Transaction PIN',
                  hintText: 'Enter 6-digit PIN',
                  prefixIcon: const Icon(Icons.lock_outline),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fast inter-bank transfer via Bakong network. Fixed fee of \$1.50 applies.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            FilledButton(
              onPressed: _canSubmit() ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor:
                    widget.positive ? AppColors.yellow : AppColors.primary,
                foregroundColor: widget.positive ? Colors.black : Colors.white,
              ),
              child: _submitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.positive ? Colors.black : Colors.white,
                      ),
                    )
                  : Text(widget.button),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    if (_submitting) return false;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return false;
    final available = WalletApiService.instance.wallet.effectiveAvailable;

    if (!widget.positive) {
      if (amount > available) return false;
      if (_getAccountValidationError() != null) return false;
      if (_accountNameController.text.trim().isEmpty) return false;
      if (_pinController.text.trim().length != 6) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    if (widget.positive) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositKhqrScreen(amount: parsed),
        ),
      );
      return;
    }

    if (_pinController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please enter your 6-digit transaction PIN.'),
        ),
      );
      return;
    }

    final rawAcct = _accountNumberController.text.trim();
    final holderName = _accountNameController.text.trim().toUpperCase();
    final destination = '$rawAcct (${_selectedBank.name} - $holderName)';

    setState(() => _submitting = true);

    try {
      if (AuthState.instance.isAuthenticated) {
        await PaymentApiService.instance.withdraw(
          amount: parsed,
          destinationAccount: destination,
          pin: _pinController.text.trim(),
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }

      if (!mounted) return;
      setState(() => _submitting = false);

      final formattedAmount = parsed.toStringAsFixed(2);
      Navigator.pop(context);

      InAppNotificationService.instance.show(
        title: 'Withdrawal to ${_selectedBank.name} Processed',
        message: 'Withdrawal of \$$formattedAmount sent to $rawAcct ($holderName).',
        icon: Icons.north_east_rounded,
        iconColor: Colors.deepOrangeAccent,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Operation failed: ${e.toString()}'),
        ),
      );
    }
  }
}
