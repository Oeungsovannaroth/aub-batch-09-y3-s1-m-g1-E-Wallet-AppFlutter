import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_wallet/core/theme/app_theme.dart';
import 'package:e_wallet/features/qr/data/khqr_helper.dart';
import 'package:e_wallet/features/transaction/presentation/screens/send_amount_screen.dart';
import 'package:e_wallet/features/transaction/presentation/screens/simulation_screen.dart';
import 'package:e_wallet/features/transaction/presentation/screens/deposit_simulation_screen.dart';
import 'package:e_wallet/features/transaction/presentation/screens/withdraw_simulation_screen.dart';
import 'package:e_wallet/features/wallet/data/wallet_api_service.dart';
import 'package:e_wallet/features/wallet/domain/models/wallet.dart';

void main() {
  group('Priority 1: KHQR Parsing & Account Inquiry Tests', () {
    test('parseKhqrPayload correctly extracts account ID and name from EMVCo payload', () {
      final payload = KhqrHelper.generateKhqrPayload(
        accountId: 'WAL-59433784',
        merchantName: 'Thida Meas',
        amount: 25.50,
      );

      final result = KhqrHelper.parseKhqrPayload(payload);
      expect(result.accountId, 'WAL-59433784');
      expect(result.payeeName, 'THIDA MEAS');
      expect(result.amount, 25.50);
    });

    test('parseKhqrPayload extracts raw WAL- token from barcode string', () {
      const rawText = 'Payment to WAL-01493803 for lunch';
      final result = KhqrHelper.parseKhqrPayload(rawText);
      expect(result.accountId, 'WAL-01493803');
    });

    testWidgets('send_amount_screen strictly disables continue when balance is 0.00', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Force empty wallet balance
      WalletApiService.instance.wallet = const WalletModel(
        id: 'w-test-1',
        walletNumber: 'WAL-TEST-000',
        balance: 0.0,
        availableBalance: 0.0,
        currency: 'USD',
        isHidden: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const SendAmountScreen(
            receiver: 'Sokha Chan',
            receiverWalletNumber: 'WAL-01493803',
          ),
        ),
      );

      // Verify available is $0.00 and no fallback $12,450.80 exists
      expect(find.text('Available: \$0.00'), findsOneWidget);
      expect(find.textContaining('12450.80'), findsNothing);

      // Enter amount 10
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('0'));
      await tester.pump();

      // Verify insufficient balance appears
      expect(find.text('Insufficient balance'), findsOneWidget);

      // Verify Continue button is disabled
      final continueButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continue'),
      );
      expect(continueButton.onPressed, isNull);
    });
  });

  group('Priority 3: Cash In / Out & Cambodian Bank Selector Tests', () {
    testWidgets('deposit simulation is renamed to Cash In', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const DepositSimulationScreen(),
        ),
      );

      expect(find.text('Cash In'), findsOneWidget);
      expect(find.text('Proceed to Cash In (KHQR)'), findsOneWidget);
      expect(find.text('Deposit simulation'), findsNothing);
    });

    testWidgets('withdraw simulation is renamed to Withdraw to Bank with Cambodian Bank selector', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const WithdrawSimulationScreen(),
        ),
      );

      expect(find.text('Withdraw to Bank'), findsOneWidget);
      expect(find.text('DESTINATION CAMBODIAN BANK'), findsOneWidget);
      expect(find.text('ABA Bank'), findsOneWidget);
      expect(find.text('(ABA)'), findsOneWidget);
      expect(find.text('Withdraw simulation'), findsNothing);
    });

    test('Cambodian Banks list includes major Cambodian licensed banks', () {
      expect(kCambodianBanks.any((b) => b.code == 'ABA'), isTrue);
      expect(kCambodianBanks.any((b) => b.code == 'ACLEDA'), isTrue);
      expect(kCambodianBanks.any((b) => b.code == 'CANADIA'), isTrue);
      expect(kCambodianBanks.any((b) => b.code == 'WING'), isTrue);
      expect(kCambodianBanks.any((b) => b.code == 'SPN'), isTrue);
    });
  });
}
